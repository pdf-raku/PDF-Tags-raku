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

      * `start`- The byte offset of the start of the marked content sequence ('BDC' operator).

      * `end` - The byte offset of the end of the marked content sequence ('EMC' operator).

      * `kids` - Any nested tagged content within the marked content sequence.

