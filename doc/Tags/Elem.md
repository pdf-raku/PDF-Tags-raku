NAME
====

PDF::Tags::Elem - Tagged PDF structural elements

SYNOPSIS
========

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

DESCRIPTION
===========

