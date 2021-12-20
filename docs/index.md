[[Raku PDF Project]](https://pdf-raku.github.io)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku)

PDF-Tags-raku (**EXPERIMENTAL**)
============

A small DOM-like API for the navigation or creation of tagged PDF files.

This module enables reading of tagged content with simple XPath queries and basic XML serialization.

Synopsis
--------

### Reading

```
use PDF::API6;
use PDF::Tags;
use PDF::Tags::Elem;

my PDF::API6 $pdf .= open: "t/pdf/tagged.pdf";
my PDF::Tags $tags .= read: :$pdf;
my PDF::Tags::Elem $root = $tags[0];
say $root.name; # Document

# DOM traversal
for $root.kids {
    say .name; # L, P, H1, P ...
}

# XPath navigation
my @tags = $root.find('Document/L/LI[1]/LBody//*')>>.name;
say @tags.join(','); # Reference,P,Code

# XML Serialization
say $root.xml;

```

### Writing
```
use PDF::Tags;
use PDF::Tags::Elem;

# PDF::API6
use PDF::API6;
use PDF::Annot;
use PDF::XObject::Image;
use PDF::XObject::Form;

my PDF::API6 $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $root = $tags.Document;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {

    $root.Header1: $gfx, {
        .say('Marked Level 1 Header',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    };

    $root.Paragraph: $gfx, {
        .say('Marked paragraph text', :position[50, 100], :font($body-font), :font-size(12));
    };

    # add a marked image
    my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
    $root.Figure: $gfx, $img, :Alt('Incandescent apparatus');

    # add a marked link annotation
    my $destination = $pdf.destination( :page(2), :fit(FitWindow) );
    my PDF::Annot $annot = $pdf.annotation: :$page, :$destination, :rect[71, 717, 190, 734];

    $root.Link: $gfx, $annot;

    # tagged XObject Form
    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my $form-elem = $root.Form;
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];

        $form-elem.Header2: $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size;
        };

        $form-elem.Paragraph: $_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size;
        };
    }

    # render the form contained in $form-elem
    $form-elem.do: $gfx, :position[150, 70];
}

$pdf.save-as: "/tmp/marked.pdf"

```

Description
-----------

A tagged PDF contains additional markup information describing the logical
document structure of PDF documents.

PDF tagging may assist PDF readers and other automated tools in reading PDF
documents and locating content such as text and images.

This module provides a DOM  like interface for traversing PDF structure and content
via tags. It also an XPath like search capability. It is designed for use in
conjunction with PDF::Class or PDF::API6.

Some, but not all PDF files have PDF tagging.  The `pdf-info.raku` script
(PDF::Class module) can be used to verify this:
```
% pdf-info.raku my.pdf |grep Tagged
Tagged:       yes
```

Standard Tags
----

Elements may be constructed using their `Tag` name or `Mnemonic`, as listed below. For example:

    $root.P: $gfx, { .say('Marked paragraph text') };

Can also be written as:

    $root.Paragraph: $gfx, { .say('Marked paragraph text') };

Documentation in this section adapted from [pdfkit](http://pdfkit.org/docs/accessibility.html).

### "Grouping" elements:

Tag | Mnemonic | Description
---------|-----|------------
Document | | whole document; must be used if there are multiple parts or articles
Part | | part of a document
Art | Article |
Sect | Section | may nest
Div | Division| generic division
BlockQuote | | block quotation
Caption | | describing a figure or table
TOC | TableOfContents | may be nested, and may be used for lists of figures, tables, etc.
TOCI | TableOfContentsItem |  table of contents (leaf) item
Index | | index (text with accompanying Reference content)
NonStruct | NonStructural | non-structural grouping element (element itself not intended to be exported to other formats like HTML, but 'transparent' to its content which is processed normally)
Private | | content only meaningful to the creator (element and its content not intended to be exported to other formats like HTML)

### "Block" elements:

Mmemonic | Tag | Description
Tag | Mnemonic | Description
---------|-----|------------
H | Heading | heading (first element in a section, etc.)
H1 - H6 | Heading1 - Heading6 | heading of a particular level intended for use only if nesting sections is not possible for some reason
P | Paragraph |
L | List | should include optional Caption, and list items
LI | ListItem | should contain Lbl and/or LBody
Lbl | Label | bullet, number, or "dictionary headword"
LBody | ListBody | (item text, or "dictionary definition"); may have nested lists or other blocks

### "Table" elements:

Tag | Mnemonic | Description
---------|-----|------------
Table | | table; should either contain TR, or THead, TBody and/or TFoot
TR | TableRow |
TH | TableHeader | table heading cell
TD | TableData | table data cell
THead | TableHead | table header row group
TBody |TableBody | table body row group; may have more than one per table
TFoot | TableFoot | table footer row group

### "Inline" elements:

Tag | Mnemonic | Description
---------|-----|------------
Span | | generic inline content
Quote | | inline quotation
Note | | e.g. footnote; may have a Lbl (see "block" elements)
Reference | | content in a document that refers to other content (e.g. page number in an index)
BibEntry | BibliographyEntry | may have a Lbl (see "block" elements)
Code | | code
Link | | hyperlink; should contain a link annotation
Annot | Annotation | annotation (other than a link)
Ruby | | Chinese/Japanese pronunciation/explanation
RB | RubyBaseText | Ruby base text
RT | RubyBaseText | Ruby annotation text
RP | RubyPunctuation |
Warichu | | Japanese/Chinese longer description
WT | WarichuText
WP | WarichuPunctuation

### "Illustration" elements (should have Alt and/or ActualText set):

Tag | Mnemonic | Description
---------|-----|------------
Figure | |
Formula | |
Form | | form widget

### Non-structure tags:

Tag | Mnemonic | Description
---------|-----|------------
Artifact | | used to mark all content not part of the logical structure
ReversedChars | | every string of text has characters in reverse order for technical reasons (due to how fonts work for right-to-left languages); strings may have spaces at the beginning or end to separate words, but may not have spaces in the middle

Classes in this Distribution
----------

- [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags) - Tagged PDF root node
- [PDF::Tags::Attr](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Attr) - A single node attribute
- [PDF::Tags::Elem](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Elem) - Structure Tree descendant node
- [PDF::Tags::Node](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node) - Abstract node
- [PDF::Tags::Node::Parent](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node/Parent) - Abstract parent node
- [PDF::Tags::Mark](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Mark) - Leaf content marker node
- [PDF::Tags::Text](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Text) - Text content node
- [PDF::Tags::ObjRef](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/ObjRef) - A reference to a PDF object (PDF::Annot, PDF::Field or PDF::XObject)
- [PDF::Tags::XML-Writer](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/XML-Writer) - XML Serializer
- [PDF::Tags::XPath](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/XPath) - XPath evaluation context

Scripts in this Distribution
------

##### `pdf-tag-dump.raku --select=XPath --omit=tag --password=Xxxx --max-depth=n --marks --graphics --/atts --/style --debug t/pdf/tagged.pdf`

Further Work
----

- Type-casting of PDF::StructElem.A to roles; as per 14.8.5. Possibly belongs in PDF::Class, however slightly complicated by the need to apply role-mapping.

- Develop a tag/accessibility checker. A low-level sanity checker that a tagged PDF meets PDF association recommendations `pdf-tag-checker.raku --ua`. See https://www.pdfa.org/wp-content/uploads/2014/06/MatterhornProtocol_1-02.pdf and Wikipedia Clause 7 guidelines:

  - Complete tagging of "real content" in logical reading order
  - Tags must correctly represent the document's semantic structures (headings, lists, tables, etc.)
  - Problematic content is prohibited, including illogical headings, the use of color/contrast to convey information, inaccessible JavaScript, and more
  - Meaningful graphics must include alternative text descriptions
  - Security settings must allow assistive technology access to the content
  - Fonts must be embedded, and text mapped to Unicode

The PDF accessibility standard ISO 14289-1 cannot be distributed and needs to be [purchased from ISO](https://www.iso.org/standard/64599.html).

- Editing. Currently the API primarily runs in `create` or `read` modes, but doesn't readily support editing tags into existing content. More work is also
needed in the PDF::Content module to support content editing.
