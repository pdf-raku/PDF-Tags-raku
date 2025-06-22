#| Marked content reference
unit class PDF::Tags::Mark;

use PDF::Tags::Tag;
also is PDF::Tags::Tag;

use PDF::COS;
use PDF::COS::TextString;
use PDF::Content::Tag;
use PDF::Content::Canvas;
# PDF::Class
use PDF::Page;
use PDF::MCR;
use PDF::XObject::Form;

has PDF::Tags::Node::Parent $.parent is rw;
has PDF::Content::Canvas $.Stm;

sub mcr(Int:D $MCID, :$Stm, :$Pg) {
    my PDF::MCR() $cos = %(
        :Type( :name<MCR> ),
        :$MCID,
    );
    $cos<Stm> = $_ with $Stm;
    $cos<Pg>  = $_ with $Pg;
    $cos;
}

method set-cos($value) {
    self.set-value($value);
    given $.mcid -> UInt:D $MCID {
        my $cos = $MCID;
        given $value.canvas {
            when PDF::XObject::Form {
                $!Stm = $_;
                $cos = mcr($MCID, :$!Stm, :$.Pg);
            }
            when PDF::Page {
                my $Pg = $_;
                with self.parent.Pg {
                    $cos = mcr($MCID, :$Pg)
                        unless $_ === $Pg;
                }
                else {
                    $_ = $Pg;
                }
            }
            # unlikely
            default { warn "can't mark object of type {.WHAT.raku}"; }
        }
        callwith($cos);
    }
}

multi submethod TWEAK(PDF::Content::Tag:D :$cos!) {
    self.set-cos($cos);
}
 
multi submethod TWEAK(UInt:D :cos($mcid)!) {
    with self.Stm // self.Pg -> PDF::Content::Canvas $canvas {
        with self.root.canvas-tags($canvas){$mcid} {
            self.set-cos($_);
        }
        else {
            die "unable to resolve MCID $mcid on canvas {$canvas.obj-num} {$canvas.gen-num} R";
        }
    }
    else {
        die "no current marked-content page";
    }
}

method set-attribute(Str() $key, $val) {
    fail "todo: update marked content attributes";
    callsame();
}

method ast { $.root.marks ?? :Mark[ callsame() ] !! Empty }

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

  The `:marks` option can be used to override this behaviour and see raw tags:
     =begin code :lang<raku>
     my PDF::Tags $tags .= read: :$pdf, :marks;
     say "first mark is: " ~ $tags<//mark()[0]>;
     =end code
  =end item

  =begin item
  There is commonly a one-to-one relationship between a parent element and its child marked content element.
  Multiple child tags may indicate that the tag spans graphical boundaries. For example a paragraph element (name 'P')
  usually has a single child marked content sequence, but may have multiple child tags, if the paragraph spans pages.
     =begin code :lang<raku>
     my $gfx = $pdf.add-page.gfx;
     my $para = $dom.Paragraph;
     $para.mark: { $gfx.say: "This logical paragraph starts on one page...", :position[30, 50]; }
     $gfx = $pdf.add-page.gfx;
     $para.mark: { $gfx.say: "and ends on another.", :position[30, 680]; }
     =end code
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

    =item `canvas` - The owner of the content stream; a PDF::Page or PDF::XObject::Form object.

    =item `start` - The position of the start of the marked content sequence ('BDC' operator).

    =item `end` - The position of the end of the marked content sequence ('EMC' operator).


=end pod
