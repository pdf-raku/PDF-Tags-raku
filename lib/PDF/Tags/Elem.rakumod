use PDF::Tags::Node::Parent;

class PDF::Tags::Elem
    is PDF::Tags::Node::Parent {

    use PDF::COS;
    use PDF::COS::Dict;
    use PDF::COS::Stream;
    use PDF::Content;
    use PDF::Content::Graphics;
    use PDF::Tags::Node :&build-node;
    use PDF::Tags::ObjRef;
    use PDF::Tags::Mark;
    # PDF:Class
    use PDF::OBJR;
    use PDF::MCR;
    use PDF::Page;
    use PDF::StructElem;
    use PDF::XObject;
    use PDF::XObject::Image;
    use PDF::XObject::Form;
    use PDF::Class::StructItem;

    method cos(--> PDF::StructElem) handles <ActualText Alt> { callsame() }
    has PDF::Tags::Node::Parent $.parent is rw = self.root;
    has Hash $!attributes;
    has Str $.name is built;
    has Str $.class is built;
    has Bool $!hash-init;

    method attributes {
        $!attributes //= do {
            my %atts;
            for $.cos.attribute-dicts -> Hash $atts {
                %atts{$_} = $atts{$_}
                    for $atts.keys
            }

            unless %atts {
                for $.cos.class-map-keys {
                    with $.root.class-map{$_} -> $atts {
                        %atts{$_} = $atts{$_}
                            for $atts.keys
                    }
                }
            }

            %atts<class> = $_ with $!class;

            %atts;
        }
    }

    method build-kid($) {
        given callsame() {
            when ! $.root.marks && $_ ~~ PDF::Tags::Mark {
                # skip marked content tags. just get the aggregate text
                $.build-kid(.text);
            }
            default {
                $_;
            }
        }
    }

    method Hash {
       my $store := callsame();
       $!hash-init //= do {
           $store{'@' ~ .key} = .value
               for self.attributes.pairs;
           True;
       }
       $store;
    }

    multi method AT-KEY(Str $_ where .starts-with('@')) {
        self.attributes{.substr(1)};
    }

    method text { $.ActualText // $.kids.map(*.text).join }

    submethod TWEAK(Str :$Alt) {
        self.Pg = $_ with self.cos.Pg;
        my Str:D $tag = self.cos.tag;
        with self.root.role-map{$tag} {
            $!class = $tag;
            $!name = $_;
        }
        else {
            $!name = $tag;
        }
        self.cos.Alt = $_ with $Alt;
    }

    method mark(PDF::Content $gfx, &action, :$name = self.name, |c) {
        my $*ActualText = ''; # Populated by PDF::Content::Text::Block
        my PDF::Content::Tag $tag = $gfx.tag($name, &action, :mark, |c);
        my PDF::Tags::Mark $kid = self.add-kid: $tag;
        self.ActualText ~= $*ActualText;

        given $gfx.parent.StructParents -> $idx is rw {
            $idx //= $.root.parent-tree.max-key + 1
                if $gfx.owner ~~ PDF::Page;
            $.root.parent-tree[$_+0][$kid.mcid] //= self.cos
                with $idx;
        }

        $kid;
    }

    # build intermediate node
    multi method copy-tree(PDF::Tags::Elem $from-elem = self, PDF::XObject::Form:D :$Stm!, :$parent!) {
        my PDF::StructElem $from-cos = $from-elem.cos;
        my $S = $from-cos.S;
        my PDF::StructElem $P = $parent.cos;
        my PDF::StructElem $to-cos =  PDF::COS.coerce: %(
            :Type( :name<StructElem> ),
            :$S,
            :$P,
            :$Stm,
        );
        for <A C T Lang Alt E ActualText Pg> -> $k {
            $to-cos{$k} = $_ with $from-cos{$k};
        }
        $to-cos<Pg> = $_ with $.Pg;
        my PDF::Tags::Elem $to-elem = build-node($to-cos, :$.root, :$parent);
        for $from-elem.kids {
            my PDF::Tags::Node:D $kid = $.copy-tree($_, :$Stm, :parent($to-elem));
            $to-elem.add-kid: $kid;
        }
        $to-elem;
    }

    # build leaf nodes
    multi method copy-tree(PDF::Tags::Mark $item, PDF::COS::Stream :$Stm!, PDF::Tags::Elem :$parent!) {
        $item.clone: :$Stm, :$parent;
    }
    multi method copy-tree(PDF::Tags::ObjRef $ref) {
        $ref.cos;
    }

    method !do-reference(PDF::Content $gfx, PDF::XObject $xobj, |c) {
        my @rect = $gfx.do($xobj, |c);
        self.reference($gfx, $xobj);
        self!bbox($gfx, @rect);
        @rect;
    }

    multi method do(PDF::Content $gfx, PDF::XObject::Image $img, *%o) {
        self!do-reference($gfx, $img, |%o);
    }

    multi method do(PDF::Content $gfx, PDF::XObject::Form $xobj, *%o) {

        if $xobj.StructParents.defined // self!setup-parents($xobj) {
            my @rect = $gfx.do($xobj, %o);
            my $owner = $gfx.owner;
            my PDF::Page $Pg = $owner
            if $owner ~~ PDF::Page;

            given $xobj.StructParents {
                # potentially lossy. parent-tree only includes
                # marked content references
                my Array $parents = self.root.parent-tree[$_+0];

                for $parents.keys {
                    # copy sub-trees
                    my PDF::StructElem $cos = $parents[$_];
                    my PDF::Tags::Elem $elem = build-node($cos, :$.root, :$Pg, :parent(self));
                    self.add-kid: $elem.copy-tree(:Stm($xobj), :parent(self));
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
        my PDF::XObject @xobjects = @elems.map({
            when PDF::Tags::Mark { .Stm }
            when XObjRef { .cos.object }
            default { Mu }
        }).grep(*.defined);

        @xobjects ||= do {
            my @kids;
            @kids.append: .kids for @elems;
            find-xobjects(@kids);
        }
    }
    # smart do on a subtree containing an x-object
    multi method do(PDF::Content $gfx, *%o) {
        my PDF::XObject @xobjects = find-xobjects([self]).unique
            || die "no xobject found";
        die "element cointains multiple xobjects" if @xobjects > 1;
        my $xobj = @xobjects[0];

        my @rect = $gfx.do($xobj, |%o);

        given $xobj {
            when PDF::XObject::Form && !.StructParent.defined {
                if .StructParents.defined {
                    my PDF::Tags::Elem:D $parent = self.parent;
                    $parent.add-kid: self.copy-tree(:Stm($_), :$parent);
                }
                else {
                    # automatically create /StructParents or /StructParent entries
                    self!setup-parents($_)
                        // self.reference($gfx, $_);
                }
            }
            default {
                self.reference($gfx, $_);
            }
        }

        self!bbox($gfx, @rect);
        @rect;
    }

    multi sub find-parents(PDF::Tags::Elem $_, $xobj) {
        my PDF::Tags::Elem @parents;
        if .kids.first({
            $_ ~~ PDF::Tags::Mark && .cos.Stm === $xobj
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
            $.root.parent-tree[$idx] = [ @parents.map(*.cos) ];
            $xobj.StructParents = $idx;
        }
        else {
            Nil;
        }
    }

    has Bool $!atts-reset;
    method set-attribute(Str() $key, $val) {
        given self.cos<A> {
            # could be an array of dicts + revisions
            $_ = %(self.attributes)
                unless $_ ~~ Hash:D;
            .{$key} = self.attributes{$key} = $val;
       }
     }

    method !bbox($gfx, @rect) {
        self.set-bbox($gfx, @rect)
            if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';
    }

    method set-bbox(PDF::Content $gfx, @rect) {
        self.set-attribute('BBox', $gfx.base-coords(@rect).Array);
    }

    method reference(PDF::Content $gfx, PDF::Class::StructItem $Obj) {
        my PDF::OBJR $ref = PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj,
        );

        given $gfx.owner {
            when PDF::Page { $ref<Pg> = $_ }
        }
        self.add-kid: $ref;

        without $Obj.StructParent {
            $_ = $.root.parent-tree.max-key + 1;
            $.root.parent-tree[$_ + 0] = self.cos;
        }
        self;
    }
}

=begin pod
=head1 NAME

PDF::Tags::Elem - Tagged PDF structural elements

=head1 SYNOPSIS

  use PDF::Content::Tag :IllustrationTags, :StructureTags, :ParagraphTags;
  use PDF::Tags;
  use PDF::Tags::Elem;
  use PDF::Class;

  # element creation
  my PDF::Class $pdf .= new;
  my PDF::Tags $tags .= create: :$pdf;
  my PDF::Tags::Elem $doc = $tags.add-kid(Document);

  my $page = $pdf.add-page;
  my $font = $page.core-font: :family<Helvetica>, :weight<bold>;

  $page.graphics: -> $gfx {
      my PDF::Tags::Elem $header = $doc.add-kid(Header1);
      my PDF::Tags::Mark $mark = $header.mark: $gfx, {
        .say: 'This header is marked',
              :$font,
              :font-size(15),
              :position[50, 120];
        }

      # add a figure with a caption
      my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
      $doc.add-kid(Figure, :Alt('Incandescent apparatus'))
          .do: $gfx, $img, :position[50, 70];
      $doc.add-kid(Caption).mark: $gfx, {
          .say("Eureka!", :position[40, 60]),
      }
  }

  $pdf.save-as: "/tmp/tagged.pdf";

  # reading
  $pdf .= open: "/tmp/tagged.pdf";
  $tags .= read: :$pdf;
  $doc = $tags[0]; # root element
  say $doc.name; # Document
  say $doc.kids>>.name.join(','); # H1,Figure,Caption

=head1 DESCRIPTION

PDF::Tags::Elem represents one node in the structure tree.

=head1 METHODS

This class inherits from PDF::Tags::Node::Parent and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`)

=begin item
attributes

  my %atts = $elem.attributes;

return attributes as a Hash
=end item

=begin item
set-attribute

  $elem.set-attribute('BBox', [0, 0, 200, 50]);

Set a single attribute by key and value.
=end item

=begin item
ActualText

   my $text = $elem.ActualText;

Return predefined actual text for the structual node and any children. This is an optional property.

Note that ActualText is an optional field in the structure tree. The `text()` method (below) is recommended for generalised text extraction.

=end item

=begin item
text

   my Str $text = $elem.text();

Return the text for the node and its children. Use `ActualText()` if present. Otherwise this is computed as concationated child text elements.
=end item

=begin item
Alt

   my Str $alt-text = $elem.Alt();

Return an alternate description for the structual element and its children in human readable form.
=end item

=begin item
do

    my @rect = $elem.do($page.gfx, $img);

Place an XObject Image or Form as a structural item.

If the object is a Form that contains marked content, its structure is appended to the element. Any other form or image is referenced (see below).

The image argument can be omitted, if the element sub-tree contains an xobject image:

    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my $form-elem = $doc.add-kid(Form);
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.add-kid(Header2).mark: $_, { .say: "Tagged XObject header", :font($header-font), :$font-size};
        $form-elem.add-kid(Paragraph).mark: $_, { .say: "Some sample tagged text", :font($body-font), :$font-size};
    }

    $form-elem.do($page.gfx, :position[150, 70]);

This is the recommended way of composing an XObject Form with marked content. It will ensure the logical structure is accurately captured, including any nested tags and object references to images, or annotations.

=end item

=begin item
reference

    $elem.reference($page.gfx, $object);

Create and place a reference to an XObject (type PDF::XObject) , Annotation (type PDF::Annot), or Form (type PDF::Form);

=end item

=end pod

