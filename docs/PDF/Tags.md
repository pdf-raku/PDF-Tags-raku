[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)

class PDF::Tags
---------------

Tagged PDF root node

Synopsis
--------

    use PDF::Content::Tag :ParagraphTags;
    use PDF::Class;
    use PDF::Tags;
    use PDF::Tags::Elem;

    # create tags
    my PDF::Class $pdf .= new;

    my $page = $pdf.add-page;
    my $font = $page.core-font: :family<Helvetica>, :weight<bold>;
    my $body-font = $page.core-font: :family<Helvetica>;

    my PDF::Tags $tags .= create: :$pdf;
    my PDF::Tags::Elem $doc = $tags.Document;

    $page.graphics: -> $gfx {
        $doc.Paragraph: $gfx, {
            .say('Hello tagged world!',
                 :$font,
                 :font-size(15),
                 :position[50, 120]);
        }
    }
    $pdf.save-as: "tagged.pdf";

    # search tags
    my PDF::Tags @elems = $tags.find('Document//*');

Description
-----------

A tagged PDF contains additional logical document structure. For example in terms of Table of Contents, Sections, Paragraphs or Indexes.

The logical structure follows a layout model that is similar to (and is designed to map to) other layouts such as XML, HTML, TeX and DocBook.

The leaves of the structure tree are usually references to: - sections Page or XObject Form content, - images, annotations or Acrobat forms

In addition to the structure tree, PDF documents may contain additional page level mark-up that further assist with accessibility and organization and processing of the content stream.

This module is under construction as an experimental tool for reading or creating tagged PDF content.

Methods
-------

this class inherits from [PDF::Tags::Node::Parent](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node/Parent) and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`)

### method create

    method create(PDF::Class :$pdf!) returns PDF::Tags

Create an empty tagged PDF structure in a PDF.

