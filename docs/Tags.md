NAME
====

PDF::Tags - Tagged PDF root node

SYNOPSIS
========

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
    my PDF::Tags::Elem $doc = $tags.add-kid(Document);

    $page.graphics: -> $gfx {
        $doc.add-kid(Paragraph).mark: $gfx, {
            .say('Hello tagged world!',
                 :$font,
                 :font-size(15),
                 :position[50, 120]);
        }
    }
    $pdf.save-as: "t/pdf/tagged.pdf";

    # read tags
    my PDF::Class $pdf .= open: "t/pdf/tagged.pdf");
    my PDF::Tags $tags .= read: :$pdf;
    my PDF::Tags::Elem $doc = $tags[0];
    say "document root {$doc.name}";
    say " - child {.name}" for $doc.kids;

    # search tags
    my PDF::Tags @elems = $tags.find('Document//*');

DESCRIPTION
===========

A tagged PDF contains additional logical document structure. For example in terms of Table of Contents, Sections, Paragraphs or Indexes.

The logical structure follows a layout model that is similar to (and is designed to map to) other layouts such as XML, HTML, TeX and DocBook.

The leaves of the structure tree are usually references to: - sections Page or XObject Form content, - images, annotations or Acrobat forms

In addition to the structure tree, PDF documents may contain additional page level mark-up that further assist with accessibility and organization and processing of the content stream.

This module is under construction as an experimental tool for reading or creating tagged PDF content.

METHODS
=======

this class inherits from PDF::Tags::Node::Parent and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`)

  * read

        my PDF::Tags $tags .= read: :$pdf;

    Read tagged PDF structure from an existing file that has been previously tagged.

  * create

        my PDF::Tags $tags .= create: :$pdf;

    Create an empty tagged PDF structure in a PDF object.

    The PDF::Tags API currently only supports writing of tagged content in read-order. Hence the PDF object should be empty; content and tags should be co-created in read-order.

