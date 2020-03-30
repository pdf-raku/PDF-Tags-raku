use PDF::Tags::Node::Parent;

class PDF::Tags::Mark
    is PDF::Tags::Node::Parent {

    use PDF::Page;
    use PDF::COS;
    use PDF::COS::TextString;
    use PDF::Content::Tag;
    use PDF::Content::Graphics;
    use PDF::XObject::Form;
    use PDF::MCR;

    has PDF::Tags::Node::Parent $.parent is rw;
    has %!attributes;
    has Bool $!atts-built;
    has Str $!actual-text;
    has PDF::Content::Graphics $.Stm;
    has PDF::Content::Tag $.mark is built handles<name mcid elems>;

    method set-cos($!mark) {
        my PDF::Page $Pg = $.Pg;
        given $!mark.owner {
            when PDF::XObject::Form { $!Stm = $_ }
            when PDF::Page { $Pg = $_; }
            # unlikely
            default { warn "can mark object of type {.WHAT.raku}"; }
        }
        my PDF::MCR $mcr;
        with $.mcid -> $MCID {
            # only linked into the struct-tree if it has an MCID attribute

            $mcr = PDF::COS.coerce: %(
                :Type( :name<MCR> ),
                :$MCID,
            );
            $mcr<Pg> = $_ with $Pg;
            $mcr<Stm> = $_ with $!Stm;
        }
        callwith($mcr);
    }

    multi submethod TWEAK(PDF::Content::Tag:D :cos($_)!) {
        self.set-cos($_);
    }
    multi submethod TWEAK(UInt:D :$cos!) {
        with self.Stm // self.Pg -> PDF::Content::Graphics $_ {
            with self.root.graphics-tags($_){$cos} {
                self.set-cos($_);
            }
            else {
                die "unable to resolve MCID: $cos";
            }
        }
        else {
            die "no current marked-content page";
        }
    }
    method cos(--> PDF::MCR) { callsame() }
    method attributes {
        $!atts-built ||= do {
            %!attributes = $!mark.attributes;
            $!actual-text = PDF::COS::TextString.new: :value($_)
                with %!attributes<ActualText>;
            True;
        }
        %!attributes;
    }
    method ActualText {
        $.attributes unless $!atts-built;
        $!actual-text;
    }
    method text { $.ActualText // $.kids.map(*.text).join }
    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        self.kids-raw[$i] //= self.build-kid($!mark.kids[$i]);
    }
}

=begin pod
=head1 NAME

PDF::Tags::Mark - Marked content reference

=head1 SYNOPSIS

  use PDF::Content::Tag :StructureTags, :ParagraphTags;
  use PDF::Tags;
  use PDF::Tags::Elem;
  use PDF::Tags::Mark;

  # PDF::Class
  use PDF::Class;
  use PDF::Page;

  my PDF::Class $pdf .= new;
  my PDF::Tags $tags .= create: :$pdf;
  # create the document root
  my PDF::Tags::Elem $doc = $tags.add-kid(Document);

  my PDF::Page $page = $pdf.add-page;

  $page.graphics: -> $gfx {

      my PDF::Tags::Mark $mark = $doc.add-kid(Paragraph).mark: $gfx, {
          .say: 'Marked paragraph text', :position[50, 100];
      }

      note $mark.name.Str;         # 'P'
      note $mark.attributes<MCID>; # 0
      note $mark.mcid;             # 0
      note $mark.mark.gist;        # <P MCID="0"/>
      note $mark.parent.text;      # 'Marked paragraph text'
      note $mark.parent.xml;       # '<P>Marked paragraph text</P>'
  }

=head1 DESCRIPTION

A mark is a reference to an area of marked content within a page or xobject form's content stream. A mark is a leaf node of a tagged PDF's logical structure and is usually parented by a PDF::Tags::Elem object.

=head1 METHODS

=begin item
name

The tag, as it appears in the marked content stream.

=end item

=begin item
attributes

The raw dictionary, as it appears in the marked content stream.
=end item

=begin item
mcid

The Marked Content ID within the content stream. These are usually number in sequence, within a stream, starting at zero.

=end item

=begin item
mark

The low-level PDF::Content::Tag object, which contains futher details on the tag:

    =item `owner` - The owner of the content stream; a PDF::Page or PDF::XObject::Form
    object.

    =item `start`- The byte offset of the start of the marked content sequence ('BDC' operator).

    =item `end` - The byte offset of the end of the marked content sequence ('EMC' operator).

    =item `kids` - Any nested tagged content within the marked content sequence.

=end item

=end pod
