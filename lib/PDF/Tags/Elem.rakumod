#| represents one node in the structure tree.
unit class PDF::Tags::Elem;

use PDF::Tags::Node::Parent :&att-owner;
also is PDF::Tags::Node::Parent;

use PDF::COS;
use PDF::COS::Dict;
use PDF::COS::Name;
use PDF::COS::Stream;
use PDF::Content;
use PDF::Content::Canvas;
use PDF::Tags::Mark;
use PDF::Tags::Node :&build-node, :TagName;
use PDF::Tags::ObjRef;
use PDF::Tags::Text;
# PDF:Class
use PDF::Class::StructItem;
use PDF::Attributes;
use PDF::MCR;
use PDF::OBJR;
use PDF::Page;
use PDF::StructElem;
use PDF::XObject::Form;
use PDF::XObject::Image;
use PDF::XObject;

method cos(--> PDF::StructElem) handles <ActualText Alt Lang> { callsame() }
has PDF::Tags::Node::Parent $.parent is rw = self.root;
has Hash $!attributes;
has TagName $.name is built;
has Str $.role is built;
has List $!classes;

method classes { $!classes //= $.cos.class-map-keys }

method name is rw {
    Proxy.new(
        FETCH => { $!name },
        STORE => -> $, $!name {
            self.cos.tag = $!name;
        }
    );
}

sub merge-atts(%atts, PDF::Attributes $a) {
    if $a.Hash -> %a {
        my $owner = $a<O>;
        # guess owner, if not given
        $owner //= att-owner($_).head
            given %a.keys.head;
        if $owner ~~ 'Layout'|'List'|'PrintField'|'Table' {
            # standard owners (Table 341) with mutually distinct attribute names
            %atts{.key} = .value for %a;
        }
        else {
            %atts{$owner ~ ':' ~ .key} = .value for %a;
        }
    }
}

method attributes {
    $!attributes //= do {
        my %atts;
        for $.cos.attribute-dicts -> PDF::Attributes $atts {
            merge-atts(%atts, $atts);
        }

        unless %atts {
            for @.classes {
                with $.root.class-map{$_} -> PDF::Attributes $atts {
                    merge-atts(%atts, $atts);
                }
            }
        }

        %atts<role> = $_ with $!role;

        %atts;
    }
}

method build-kid($) {
    given callsame() {
        if ! $.root.marks && $_ ~~ PDF::Tags::Mark && !.attributes<Lang> {
            # dereference marked content tags. just get the aggregate text
            $.build-kid(.text);
        }
        else {
            $_;
        }
    }
}

method text returns Str { self.cos.ActualText // $.kids».text.join }

submethod TWEAK(Str :$Alt, Str :$ActualText, Str :$Lang, Str :$class, :%attributes) {
    self.set-attributes(|%attributes)
        if %attributes;
    given self.cos -> $cos {
        self.Pg = $_ with $cos.Pg;
        $cos.Alt = $_ with $Alt;
        $cos.ActualText = $_ with $ActualText;
        $cos.Lang = $_ with $Lang;
        $cos.C = PDF::COS::Name.COERCE($_) with $class;
        my Str:D $tag = $cos.tag;
        with self.root.role-map{$tag} {
            $!role = $tag;
            $!name = $_;
        }
        else {
            $!name = $tag;
        }
    }
}

method mark(PDF::Tags::Elem:D $elem: PDF::Content $gfx, &action, :$name = self.name, |c --> PDF::Tags::Mark:D) {
    temp $gfx.actual-text = ''; # Populated by PDF::Content.print()

    my PDF::Content::Tag $cos = $gfx.tag($name.fmt, &action, :mark, |c);
    my PDF::Tags::Mark:D $mark = $elem.add-kid: :$cos;
    $mark.actual-text = $gfx.actual-text;
    # Register this mark in the parent tree
    $.root.protect: {
        given $gfx.canvas.StructParents -> $idx is rw {
            $idx //= $.root.parent-tree.max-key + 1
                if $gfx.canvas ~~ PDF::Page;
            $.root.parent-tree[$_+0][$mark.mcid] //= $elem.cos
                with $idx;
        }
    }

    $mark;
}

# combined add-kid + mark
multi method add-kid(PDF::Content:D $gfx, &action, :$name!, Str :$Alt, Str :$Lang, Str :$ActualText, Str :$class, :%attributes, |c --> PDF::Tags::Elem:D) {
    given self.add-kid(:$name, :$Alt, :$Lang, :$ActualText, :$class, :%attributes) {
        .mark($gfx, &action, |c);
        $_;
    }
}

# combined add-kid + do
multi method add-kid(PDF::Content:D $gfx, PDF::XObject:D $xobj, :$name!, Str :$Alt, |c --> PDF::Tags::Elem:D) {
    given self.add-kid(:$name, :$Alt) {
        .do($gfx, $xobj, |c);
        $_;
    }
}

# combined add-kid + reference
multi method add-kid(PDF::Content:D $gfx, PDF::Class::StructItem:D $obj, :$name!, Str :$Alt, |c --> PDF::Tags::Elem:D) {
    self.add-kid(:$name, :$Alt).reference($obj, :$gfx, |c);
}

# copy intermediate node and descendants
multi method copy-tree(PDF::Tags::Elem:D $from-elem = self, PDF::XObject::Form:D :$Stm!, :$parent!) {
    my PDF::StructElem $from-cos = $from-elem.cos;
    my $S = $from-cos.S;
    my PDF::StructElem $P = $parent.cos;
    my PDF::StructElem() $to-cos = %(
        :Type( :name<StructElem> ),
        :$S,
        :$P,
    );
    for <A C T Lang Alt E ActualText> -> $k {
        $to-cos{$k} = $_ with $from-cos{$k};
    }
    $to-cos<Pg> = $_ with $.Pg // $from-cos<Pg>;
    my PDF::Tags::Elem $to-elem = build-node($to-cos, :$.root, :$parent);
    for $from-elem.kids {
        my PDF::Tags::Node:D $kid = $.copy-tree($_, :$Stm, :parent($to-elem));
        $to-elem.add-kid: :node($kid);
    }
    $to-elem;
}

# copy leaf node
multi method copy-tree(PDF::Tags::Mark $item, PDF::COS::Stream :$Stm!, PDF::Tags::Elem :$parent!) {
    $item.clone: :$Stm, :$parent;
}

# copy reference
multi method copy-tree(PDF::Tags::ObjRef $ref, PDF::Tags::Elem :$parent!) {
    $ref.clone: :$parent;
}

method !do-reference(PDF::Content $gfx, PDF::XObject $xobj, |c) {
    my @rect = $gfx.do($xobj, |c);
    self.reference($xobj, :$gfx);
    self!bbox($gfx, @rect);
    @rect;
}

multi method do(PDF::Content $gfx, PDF::XObject::Image $img, *%o) {
    self!do-reference($gfx, $img, |%o);
}

multi method do(PDF::Content $gfx, PDF::XObject::Form $xobj, *%o) {

    if $.root.protect({$xobj.StructParents.defined || self!setup-parents($xobj)}) {
        my @rect = $gfx.do($xobj, %o);
        my PDF::Content::Canvas $canvas = $gfx.canvas;
        my PDF::Page $Pg = $canvas
           if $canvas ~~ PDF::Page;

        given $xobj.StructParents {
            # potentially lossy. parent-tree only includes marked content references
            $.root.protect: {
                my Array $parents = self.root.parent-tree[$_+0];

                for $parents.keys {
                    # copy sub-trees
                    my PDF::StructElem $cos = $parents[$_];
                    my PDF::Tags::Elem $elem = build-node($cos, :$.root, :$Pg, :parent(self));
                    my PDF::Tags::Node $node = $elem.copy-tree(:Stm($xobj), :parent(self));
                    self.add-kid: :$node;
                }
            }
        }
        self!bbox($gfx, @rect);
        @rect;
    }
    else {
        self!do-reference($gfx, $xobj, |%o);
    }
}

# depth first search for referenced xobject
multi sub find-xobjects([]) { [] }
multi sub find-xobjects(@elems) {
    my subset XObjRef of PDF::Tags::ObjRef where .cos.object ~~ PDF::XObject;
    my PDF::XObject @xobjects = @elems.map: {
        when PDF::Tags::Mark { .Stm }
        when XObjRef { .cos.object }
        default { Empty }
    };

    @xobjects ||= do {
        my @kids;
        @kids.append: .kids for @elems;
        find-xobjects(@kids);
    }
}
# smart do on a sub-tree containing an x-object
multi method do(PDF::Tags::Elem:D $parent: PDF::Content $gfx, PDF::Tags::Elem:D $frag, *%o) {
    my PDF::XObject @xobjects = find-xobjects([$frag]).unique
        || die "no xobject found";
    die "element contains multiple xobjects" if @xobjects > 1;
    my PDF::XObject:D $Stm = @xobjects[0];
    my PDF::Tags::Elem $node = $frag.copy-tree(:$Stm, :$parent);
    if $node.name eq 'DocumentFragment' {
        $parent.add-kid(:node($_)) for $node.kids;
    }
    else {
        $parent.add-kid: :$node;
    }

    my @rect = $gfx.do($Stm, |%o);

    given $Stm {
        when PDF::XObject::Form && !.StructParent.defined {
            $.root.protect: {
                unless .StructParents.defined {
                    $node!setup-parents($_)
                        // $node.reference($_, :$gfx);
                }
            }
        }
        default {
            $node.reference($_, :$gfx);
        }
    }

    $parent!bbox($gfx, @rect);
    @rect;
}

multi sub find-parents(PDF::Tags::Elem $_, $xobj) {
    my PDF::Tags::Elem @parents;
    if .kids.first({
        $_ ~~ PDF::Tags::Mark && .Stm === $xobj
    }) {
        @parents.push: $_;
    }
    else {
        @parents.append: find-parents($_, $xobj)
            for .kids;
    }

    @parents;
}
multi sub find-parents($, $) is default { [] }

# xobject form  has marked content but no /StructParent(s) entries. Allow
# this as shortcut. Automatically wrap with elements and create a ParentTree entry
method !setup-parents(PDF::XObject::Form $xobj) {
    my @parents = find-parents(self, $xobj);
    if @parents {
        my UInt $idx := $.root.parent-tree.max-key + 1;
        $.root.parent-tree[$idx] = [ @parents».cos ];
        $xobj.StructParents = $idx;
    }
    else {
        Nil;
    }
}

method set-attribute(Str() $key, Any:D $val) {
    #Raku 2022.06+ my :($owner, $att) := att-owner($key);
    my ($owner, $att) = att-owner($key);
    fail "unable to determine owner for attribute: $key"
        unless $owner;
    $.cos.vivify-attributes(:$owner).set-attribute($att, $val);
    self.attributes{$key} = $val;
    callsame();
}
method set-attributes(*%attributes) {
    my Hash %atts-by-owner;
    for %attributes {
        #Raku 2022.06+ my :($owner, $key) := att-owner(.key);
        my ($owner, $key) = att-owner(.key);
        %atts-by-owner{$owner}{$key} = .value;
    }
    for %atts-by-owner.keys.sort -> $owner {
        my $atts = $.cos.vivify-attributes(:$owner);
        $atts.set-attribute(.key, .value)
            for %atts-by-owner{$owner}.pairs;
    }
    $!attributes = Nil; # regen on next access
}

method !bbox($gfx, @rect) {
    self.set-bbox($gfx, @rect)
        if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';
}

method set-bbox(PDF::Content $gfx, @rect) {
    self.set-attribute('BBox', $gfx.base-coords(@rect).Array);
}

multi method reference(PDF::Content $gfx, PDF::Class::StructItem $Obj) is DEPRECATED('reference($Obj, :$gfx)') {
    $.reference($Obj, :$gfx);
}
multi method reference(PDF::Class::StructItem $Obj, PDF::Content:D :$gfx! ) {
    my PDF::Page $Pg;
    given $gfx.canvas {
        when PDF::Page { $Pg = $_ }
    }
    $.reference($Obj, :$Pg);
}
multi method reference(PDF::Class::StructItem $Obj, PDF::Page :$Pg!) {
    my PDF::OBJR() $cos = %(
        :Type( :name<OBJR> ),
        :$Obj,
        ($Pg ?? :$Pg !! ()),
    );

    self.add-kid: :$cos;

    $.root.protect: {
        without $Obj.StructParent {
            $_ = $.root.parent-tree.max-key + 1;
            $.root.parent-tree[$_ + 0] = self.cos;
        }
    }
    self;
}

method style {
    callsame() //= do {
        my $s = $.root.styler.tag-style($!name, |$.attributes);
        with self.parent {
            .inherit($_) with .style;
        }
        $s;
    }
}

=begin pod

=head2 Synopsis

  use PDF::Content::Tag :IllustrationTags, :StructureTags, :ParagraphTags;
  use PDF::Tags;
  use PDF::Tags::Elem;
  use PDF::Class;

  # element creation
  my PDF::Class $pdf .= new;
  my PDF::Tags $tags .= create: :$pdf;
  my PDF::Tags::Elem $doc = $tags.Document;

  my $page = $pdf.add-page;
  my $font = $pdf.core-font: :family<Helvetica>, :weight<bold>;

  $page.graphics: -> $gfx {
      my PDF::Tags::Elem $header = $doc.Header1;
      my PDF::Tags::Mark $mark = $header.mark: $gfx, {
        .say: 'This header is marked',
              :$font,
              :font-size(15),
              :position[50, 120];
        }

      # add a figure with a caption
      my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
      $doc.Figure(:Alt('Incandescent apparatus'))
          .do: $gfx, $img, :position[50, 70];
      $doc.Caption: $gfx, {
          .say("Eureka!", :position[40, 60]),
      }
  }

  $pdf.save-as: "/tmp/tagged.pdf";

  # reading
  $pdf .= open: "/tmp/tagged.pdf";
  $tags .= read: :$pdf;
  $doc = $tags[0]; # root element
  say $doc.name; # Document
  say $doc.kids».name.join(','); # H1,Figure,Caption

=head2 Methods

This class inherits from L<PDF::Tags::Node::Parent> and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`).

=head3 method attributes

  method attributes() returns Hash
  my %atts = $elem.attributes;

Returns Attributes as a Hash. Attributes may be of various types. For example a `BBox` attribute is generally an array of four numeric values.

=head3 method set-attribute

  method set-attribute(Str $name, Any:D $value) returns Any:D;
  $elem.set-attribute('BBox', [0, 0, 200, 50]);

Set a single attribute by name and value.

=head3 method ActualText

  method ActualText() returns Str

Return predefined actual text for the structural node and any children.

Note that ActualText is an optional field in the structure tree. The `text()` method (below) is recommended for generalised text extraction.

=head3 method text

  method text() returns Str

Return the text for the node and its children. Uses `ActualText()` if present in the current node or its ancestors. Otherwise this is computed as concatenated child text elements.

=head3 method Alt

  method Alt() returns Str

Return an alternate description for the structural element and its children in human readable form.

=head3 method do

  method do(
       PDF::Content $gfx, PDF::XObject $image?, *%o
  ) returns Array
  my @rect[4] = $elem.do($page.gfx, $image);

Place an XObject Image or Form as a structural item.

If the object is a Form that contains marked content, its structure is appended to the element. Any other form or image is referenced (see below).

The image argument can be omitted, if the element sub-tree contains an xobject image:

    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my PDF::Tags::Elem $form-elem = $doc.Form;
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.Header2: $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size
        };
        $form-elem.Paragraph: $_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size};
        }

    $form-elem.do($page.gfx, :position[150, 70]);

This is the recommended way of composing an XObject Form with marked content. It will ensure the logical structure is accurately captured, including any nested tags and object references to images, or annotations.


=head3 method reference

    method reference(
        PDF::Content $gfx, PDF::Class::StructItem $Obj
    ) returns PDF::Tags::Elem

Create and place a reference to an XObject (type L<PDF::XObject>) , Annotation (type L<PDF::Annot>), or Form (type L<PDF::Form>);

=end pod

