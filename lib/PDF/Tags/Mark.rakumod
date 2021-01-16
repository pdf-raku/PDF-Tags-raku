use PDF::Tags::Node::Parent;

#| Marked content reference
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
    has PDF::Content::Tag $.value is built handles<name mcid elems>;

    method set-cos($!value) {
        my PDF::Page $Pg = $.Pg;
        given $!value.owner {
            when PDF::XObject::Form { $!Stm = $_ }
            when PDF::Page { $Pg = $_; }
            # unlikely
            default { warn "can mark object of type {.WHAT.raku}"; }
        }
        my PDF::MCR $mcr;
        with $.mcid -> $MCID {
            # only linked into the struct-tree if it has an MCID attribute

            $mcr .= COERCE: %(
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
    multi submethod TWEAK(UInt:D :cos($mcid)!) {
        with self.Stm // self.Pg -> PDF::Content::Graphics $_ {
            with self.root.graphics-tags($_){$mcid} {
                self.set-cos($_);
            }
            else {
                die "unable to resolve MCID: $mcid";
            }
        }
        else {
            die "no current marked-content page";
        }
    }
    method cos(--> PDF::MCR) { callsame() }
    method attributes {
        $!atts-built ||= do {
            %!attributes = $!value.attributes;
            True;
        }
        %!attributes;
    }
    method set-attribute(Str() $key, $val) {
        fail "todo: update marked content attributes";
        callsame();
     }
    method ActualText {
        $.attributes unless $!atts-built;
        $!actual-text //= PDF::COS::TextString.new: :value($_)
            with %!attributes<ActualText>;
    }
    method text { $.ActualText // $.kids.map(*.text).join }
    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        self.kids-raw[$i] //= self.build-kid($!value.kids[$i]);
    }
}

=begin pod

=head2 Synopsis

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
  my PDF::Tags::Elem $doc = $tags.Document;

  my PDF::Page $page = $pdf.add-page;

  $page.graphics: -> $gfx {

      my PDF::Tags::Mark $mark = $doc.Paragraph.mark: $gfx, {
          .say: 'Marked paragraph text', :position[50, 100];
      }

      note $mark.name.Str;         # 'P'
      note $mark.attributes<MCID>; # 0
      note $mark.mcid;             # 0
      note $mark.value.gist;       # <P MCID="0"/>
      note $mark.parent.text;      # 'Marked paragraph text'
      note $mark.parent.xml;       # '<P>Marked paragraph text</P>'
  }

=head2 Description

A mark is a reference to an area of marked content within a page or xobject form's content stream. A mark is a leaf node of a tagged PDF's logical structure and is usually parented by a L<PDF::Tags::Elem> object.

=head3 Notes:

  =begin item
  The default action when reading PDF files is to omit L<PDF::Tags::Mark> objects, replacing them with
  summary PDF::Tag::Text objects.

  The `:marks` option can be used to override this behaviour and see raw marks:

     my PDF::Tags $tags .= read: :$pdf, :marks;
     say "first mark is: " ~ $tags<//mark()[0]>;
  =end item

  =begin item
  There is commonly a one-to-one relationship between a parent element and its child marked content element.
  Multiple child marks may indicate that the tag spans graphical boundaries. For example a paragraph element (name 'P')
  usually has a single child marked content sequence, but may have multiple child marks, if the paragraph spans
  pages.
  =end item

=head2 Methods

=head3 method name

    use PDF::Tags::Node :TagName;
    method name () returns TagName;

The tag, as it appears in the marked content stream.

=head3 method attributes

    method attributes() returns Hash;

The raw dictionary, as it appears in the marked content stream.

=head3 method mcid

    method mcid() returns UInt

The Marked Content ID within the content stream. These are usually numbered in sequence, within a stream, starting at zero.

=head3 method value

    method value() returns PDF::Content::Tag

The low-level L<PDF::Content::Tag> object, which contains further details on the tag:

    =item `owner` - The owner of the content stream; a PDF::Page or PDF::XObject::Form object.

    =item `start` - The position of the start of the marked content sequence ('BDC' operator).

    =item `end` - The position of the end of the marked content sequence ('EMC' operator).

=end pod
