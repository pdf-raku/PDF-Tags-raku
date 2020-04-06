NAME
====

PDF::Tags::Mark - Marked content reference

SYNOPSIS
========

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

DESCRIPTION
===========

A mark is a reference to an area of marked content within a page or xobject form's content stream. A mark is a leaf node of a tagged PDF's logical structure and is usually parented by a PDF::Tags::Elem object.

Notes:
------

  * The default action when reading PDF files is to omit PDF::Tags::Mark objects, replacing them with summary PDF::Tag::Text objects.

    The `:marks` option can be used to override this behaviour and see raw marks:

        my PDF::Tags $tags .= read: :$pdf, :marks;
        say "first mark is: " ~ $tags<//mark()[0]>;

  * There is commonly a one-to-one relationship between a parent element and its child marked content element. Multiple child marks may indicate that the tag spans graphical boundaries. For example a paragraph element (name 'P') usually has a single child marked content sequence, but may have multiple child marks, if the paragraph spans pages.

METHODS
=======

  * name

    The tag, as it appears in the marked content stream.

  * attributes

    The raw dictionary, as it appears in the marked content stream.

  * mcid

    The Marked Content ID within the content stream. These are usually number in sequence, within a stream, starting at zero.

  * mark

    The low-level PDF::Content::Tag object, which contains futher details on the tag:

      * `owner` - The owner of the content stream; a PDF::Page or PDF::XObject::Form object.

      * `start`- The position of the start of the marked content sequence ('BDC' operator).

      * `end` - The position of the end of the marked content sequence ('EMC' operator).

