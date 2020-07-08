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

Description
-----------

A tagged PDF contains additional logical document structure. For example in terms of Table of Contents, Sections, Paragraphs or Indexes.

The logical structure follows a layout model that is similar to (and is designed to map to) other layouts such as XML, HTML, TeX and DocBook.

The leaves of the structure tree are usually references to: - sections Page or XObject Form content, - images, annotations or Acrobat forms

In addition to the structure tree, PDF documents may contain additional page level mark-up that further assist with accessibility and organization and processing of the content stream.

This module is under construction as an experimental tool for reading or creating tagged PDF content.

Methods
-------

this class inherits from PDF::Tags::Node::Parent and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`)

### method read

    method read(PDF::Class :$pdf!, Bool :$create) returns PDF::Tags

Read tagged PDF structure from an existing file that has been previously tagged.

The `:create` option creates a new struct-tree root, if one does not already exist.

### method create

    method create(PDF::Class :$pdf!) returns PDF::Tags

Create an empty tagged PDF structure in a PDF.

The PDF::Tags API currently only supports writing of tagged content in read-order. Hence the PDF object should be empty; content and tags should be co-created in read-order.

### method graphics-tags

    method graphics-tags(PDF::Content::Graphics) returns Hash

Renders a graphics object (Page or XObject form) and caches marked content as a hash of [PDF::Content::Tag](https://pdf-raku.github.io/PDF-Content-raku) objects, indexed by `MCID` (Marked Content ID).

Classes in this Distribution
----------------------------

  * [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/Tags) - Tagged PDF root node

  * [PDF::Tags::Attr](https://pdf-raku.github.io/PDF-Tags-raku/Attr) - A single node attribute

  * [PDF::Tags::Elem](https://pdf-raku.github.io/PDF-Tags-raku/Elem) - Structure Tree descendant node

  * [PDF::Tags::Node](https://pdf-raku.github.io/PDF-Tags-raku/Node) - Abstract node

  * [PDF::Tags::Node::Parent](https://pdf-raku.github.io/PDF-Tags-raku/Node/Parent) - Abstract parent node

  * [PDF::Tags::Mark](https://pdf-raku.github.io/PDF-Tags-raku/Mark) - Leaf content marker node

  * [PDF::Tags::Text](https://pdf-raku.github.io/PDF-Tags-raku/Text) - Text content node

  * [PDF::Tags::ObjRef](https://pdf-raku.github.io/PDF-Tags-raku/ObjRef) - A reference to a PDF object 

  * [PDF::Tags::XML-Writer](https://pdf-raku.github.io/PDF-Tags-raku/XML-Writer) - XML Serializer

  * [PDF::Tags::XPath](https://pdf-raku.github.io/PDF-Tags-raku/XPath) - XPath evaluation context

Scripts in this Distribution
----------------------------

    pdf-tag-dump.p6 --select=XPath --omit=tag --password=Xxxx --max-depth=n --marks --/atts --/style --debug t/pdf/tagged.pdf`

