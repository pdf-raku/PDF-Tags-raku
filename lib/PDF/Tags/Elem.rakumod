use PDF::Tags::Node;

class PDF::Tags::Elem is PDF::Tags::Node {

    use PDF::COS;
    use PDF::COS::Dict;
    use PDF::COS::Stream;
    use PDF::Content;
    use PDF::Content::Graphics;
    use PDF::Tags::Item :&build-item;
    use PDF::Tags::ObjRef;
    use PDF::Tags::Mark;
    # PDF:Class
    use PDF::OBJR;
    use PDF::Page;
    use PDF::StructElem;
    use PDF::XObject;
    use PDF::XObject::Image;
    use PDF::XObject::Form;
    use PDF::Class::StructItem;

    method cos(--> PDF::StructElem) { callsame() }
    has PDF::Tags::Node $.parent is rw = self.root;
    has %!attributes;
    has Bool $!atts-built;
    has Str $.name is built;
    has Str $.class is built;
    has Bool $!hash-init;

    method attributes {
        $!atts-built ||= do {
            for $.cos.attribute-dicts -> Hash $atts {
                %!attributes{$_} = $atts{$_}
                    for $atts.keys
            }

            unless %!attributes {
                for $.cos.class-map-keys {
                    with $.root.class-map{$_} -> $atts {
                        %!attributes{$_} = $atts{$_}
                            for $atts.keys
                    }
                }
            }

            %!attributes<class> = $_ with $!class;

            True;
        }

        %!attributes;
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

    method actual-text { $.cos.ActualText }

    method text { $.actual-text // $.kids.map(*.text).join }

    submethod TWEAK {
        self.Pg = $_ with self.cos.Pg;
        my Str:D $tag = self.cos.tag;
        with self.root.role-map{$tag} {
            $!class = $tag;
            $!name = $_;
        }
        else {
            $!name = $tag;
        }
    }

    method mark(PDF::Content $gfx, &action, :$name = self.name, |c) {
        my $kid = self.add-kid: $gfx.tag($name, &action, :mark, |c);

        my $idx = ($gfx.parent.StructParents //= $.root.parent-tree.max-key + 1);
        $.root.parent-tree[$idx+0][$kid.mcid] //= self.cos;

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
            :$.Pg,
            :$Stm,
        );
        for <A C T Lang Alt E ActualText> -> $k {
            $to-cos{$k} = $_ with $from-cos{$k};
        }
        my PDF::Tags::Elem $to-elem = build-item($to-cos, :$.root, :$parent);
        for $from-elem.kids {
            my PDF::Tags::Item:D $kid = $.copy-tree($_, :$Stm, :parent($to-elem));
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

    multi method do(PDF::Content $gfx, PDF::XObject::Image $img, |c) {
        self!do-reference($gfx, $img, |c);
    }

    multi method do(PDF::Content $gfx, PDF::XObject $xobj where .StructParent.defined, |c) {
        self!do-reference($gfx, $xobj, |c);
    }

    multi method do(PDF::Content $gfx, PDF::XObject::Form $xobj, |c) {
        my @rect = $gfx.do($xobj, |c);

        my $owner = $gfx.owner;
        my PDF::Page $Pg = $owner
            if $owner ~~ PDF::Page;

        with $xobj.StructParents {
            # avoid rendering the xobject, if possible; likely to
            # work better with foreign xobjects
            my Array $parents = self.root.parent-tree[$_+0];

            for $parents.keys {
                # copy sub-trees
                my PDF::StructElem $cos = $parents[$_];
                my PDF::Tags::Elem $elem = build-item($cos, :$.root, :$Pg, :parent(self));
                self.add-kid: $elem.copy-tree(:Stm($xobj), :parent(self));
                
            }
        }
        else {
            # automatically create /StructParents or /StructParent entries
            self!auto-parent($xobj, :$owner, :parent(self))
                // self.reference($gfx, $xobj);
        }

        self!bbox($gfx, @rect);
        @rect;
    }

    # xobject form  has marked content but no /StructParent(s) entries. Allow
    # this as shortcut. Automatically wrap with elements and create a ParentTree entry
    method !auto-parent(PDF::XObject::Form $content, PDF::Content::Graphics :$owner!) {
        my PDF::Content::Tag @tags = $content.gfx.tags.descendants.grep(*.mcid.defined);
        if @tags {
            $content.StructParents //= do {
                my PDF::Page $Pg = $owner
                    if $owner ~~ PDF::Page;
                my UInt $idx := $.root.parent-tree.max-key + 1;
                my @parents =  @tags.map: {
                    my PDF::Content::Tag $mark = .clone(:$owner, :$content);
                    my $name = $mark.name;
                    my $kid = self.add-kid($name, :$Pg);
                    $kid.add-kid: $mark;
                    $kid;
                }
                $.root.parent-tree[$idx] = [ @parents.map(*.cos) ];
                $idx;
            }
        }
        else {
            Nil;
        }
    }

    method !bbox($gfx, @rect) {
        self.set-bbox($gfx, @rect)
            if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';
    }

    method set-bbox(PDF::Content $gfx, @rect) {
        self.attributes<BBox> = $gfx.base-coords(@rect).Array;
    }

    method reference(PDF::Content $gfx, PDF::Class::StructItem $Obj) {
        my PDF::Page $Pg = $gfx.owner;
        self.add-kid: PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj,
            :$Pg;
        );
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
      $doc.add-kid(Figure).do: $gfx, $img, :position[50, 70];
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

=end pod
