use PDF::Tags::Node::Parent;

#| represents one node in the structure tree.
class PDF::Tags::Elem
    is PDF::Tags::Node::Parent {

    use PDF::COS;
    use PDF::COS::Dict;
    use PDF::COS::Stream;
    use PDF::Content;
    use PDF::Content::Graphics;
    use PDF::Tags::Node :&build-node, :TagName;
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
    has TagName $.name is built;
    has Str $.class is built;

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

    method mark(PDF::Content $gfx, &action, :$name = self.name, |c --> PDF::Tags::Mark) {
        my $*ActualText = ''; # Populated by PDF::Content::Text::Block
        my PDF::Content::Tag $cos = $gfx.tag($name, &action, :mark, |c);
        my PDF::Tags::Mark $kid = self.add-kid: :$cos;
        self.ActualText ~= $*ActualText;

        # Register this mark in the parent tree
        given $gfx.parent.StructParents -> $idx is rw {
            $idx //= $.root.parent-tree.max-key + 1
                if $gfx.owner ~~ PDF::Page;
            $.root.parent-tree[$_+0][$kid.mcid] //= self.cos
                with $idx;
        }

        $kid;
    }

    # copy intermediate node and descendants
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
                    my PDF::Tags::Node $node = $elem.copy-tree(:Stm($xobj), :parent(self));
                    self.add-kid: :$node;
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
    # smart do on a sub-tree containing an x-object
    multi method do(PDF::Content $gfx, *%o) {
        my PDF::XObject @xobjects = find-xobjects([self]).unique
            || die "no xobject found";
        die "element contains multiple xobjects" if @xobjects > 1;
        my $xobj = @xobjects[0];

        my @rect = $gfx.do($xobj, |%o);

        given $xobj {
            when PDF::XObject::Form && !.StructParent.defined {
                if .StructParents.defined {
                    my PDF::Tags::Elem:D $parent = self.parent;
                    my PDF::Tags::Node $node = self.copy-tree(:Stm($_), :$parent);
                    $parent.add-kid: :$node;
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
    method set-attribute(Str() $key, Any:D $val) {
        given self.cos<A> {
            # could be an array of dicts + revisions
            $_ = %(self.attributes)
                unless $_ ~~ Hash:D;
            .{$key} = self.attributes{$key} = $val;
       }
       callsame();
     }

    method !bbox($gfx, @rect) {
        self.set-bbox($gfx, @rect)
            if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';
    }

    method set-bbox(PDF::Content $gfx, @rect) {
        self.set-attribute('BBox', $gfx.base-coords(@rect).Array);
    }

    method reference(PDF::Content $gfx, PDF::Class::StructItem $Obj) {
        my PDF::OBJR $cos = PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj,
        );

        given $gfx.owner {
            when PDF::Page { $cos<Pg> = $_ }
        }
        self.add-kid: :$cos;

        without $Obj.StructParent {
            $_ = $.root.parent-tree.max-key + 1;
            $.root.parent-tree[$_ + 0] = self.cos;
        }
        self;
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
  my PDF::Tags::Elem $doc = $tags.add-kid: :name(Document);

  my $page = $pdf.add-page;
  my $font = $page.core-font: :family<Helvetica>, :weight<bold>;

  $page.graphics: -> $gfx {
      my PDF::Tags::Elem $header = $doc.add-kid: :name(Header1);
      my PDF::Tags::Mark $mark = $header.mark: $gfx, {
        .say: 'This header is marked',
              :$font,
              :font-size(15),
              :position[50, 120];
        }

      # add a figure with a caption
      my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
      $doc.add-kid(:name(Figure), :Alt('Incandescent apparatus'))
          .do: $gfx, $img, :position[50, 70];
      $doc.add-kid(:name(Caption)).mark: $gfx, {
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

=head2 Methods

This class inherits from PDF::Tags::Node::Parent and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`)

=head3 method attributes

  method attributes() returns Hash
  my %atts = $elem.attributes;

Returns Attributes as a Hash. Attributes may be of various types. For example a `BBox` attribute is generally an array of four numeric values.

=head3 method set-attribute

  method setattribute(Str $name, Any:D $value) returns Any:D;
  $elem.set-attribute('BBox', [0, 0, 200, 50]);

Set a single attribute by name and value.

=head3 method ActualText

  method ActualText() returns Str

Return predefined actual text for the structural node and any children.

Note that ActualText is an optional field in the structure tree. The `text()` method (below) is recommended for generalised text extraction.

=head3 method text

  method text() returns Str

Return the text for the node and its children. Uses `ActualText()` if present. Otherwise this is computed as concatenated child text elements.

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
    my PDF::Tags::Elem $form-elem = $doc.add-kid: :name(Form);
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.add-kid(:name(Header2)).mark: $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size
        };
        $form-elem.add-kid(:name(Paragraph)).mark: $_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size};
        }

    $form-elem.do($page.gfx, :position[150, 70]);

This is the recommended way of composing an XObject Form with marked content. It will ensure the logical structure is accurately captured, including any nested tags and object references to images, or annotations.


=head3 method reference

    method reference(
        PDF::Content $gfx, PDF::Class::StructItem $Obj
    ) returns PDF::Tags::Elem

Create and place a reference to an XObject (type PDF::XObject) , Annotation (type PDF::Annot), or Form (type PDF::Form);

=end pod

