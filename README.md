[[Raku PDF Project]](https://pdf-raku.github.io)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku)

PDF-Tags-raku
============

A small DOM-like API for the creation of tagged PDF files for accessibility purposes.

This module enables PDF tagged content manipulation, construction,
XPath queries and basic XML serialization.

See also [PDF::Tags::Reader](https://pdf-raku.github.io/PDF-Tags-Reader-raku), which is designed to read
content from existing tagged PDF files.

Synopsis
--------

```raku
use PDF::Tags;
use PDF::Tags::Elem;

use PDF::API6;
use PDF::Page;
use PDF::XObject::Image;

my PDF::API6 $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $doc = $tags.Document: :Lang<en-NZ>;

my PDF::Page $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {

    $doc.Header1: $gfx, {
        .say('Marked Level 1 Header',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    };

    $doc.Paragraph: $gfx, {
        .say('Marked paragraph text', :position[50, 100], :font($body-font), :font-size(12));
    };

    # add a marked image
    my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
    $doc.Figure: $gfx, $img, :Alt('Incandescent apparatus');

}

$pdf.save-as: "/tmp/synopsis.pdf"

```

Description
-----------

A tagged PDF contains additional markup information describing the logical
document structure of PDF documents.

PDF tagging may assist PDF readers and other automated tools in reading PDF
documents and locating content such as text and images.

This module provides a DOM  like interface for creating and traversing PDF structure and
content via tags. It also an XPath like search capability. It is designed for use in
conjunction with PDF::Class or PDF::API6.

Standard Tags
----

Elements may be constructed using their `Tag` name or `Mnemonic`, as listed below. For example:

    $root.P: $gfx, { .say('Marked paragraph text') };

Can also be written as:

    $root.Paragraph: $gfx, { .say('Marked paragraph text') };

Or as:

    $root.add-kid(:name<P>).mark: $gfx, { .say('Marked paragraph text') };

### "Grouping" elements:

Tag | Mnemonic | Description
---------|-----|------------
Document | | Whole document; must be used if there are multiple parts or articles
Part | | Large division of a document; may group smaller units of content together, such as Division, Article, or Section elements.
Art | Article | Self-contained body of text considered to be a single narrative.
Sect | Section | General container element type that is usually a component of a Part or Article element
Div | Division| Generic block element or group of element
BlockQuote | | A large portion of text referencing content from another source
Caption | | Description of a Figure or Table
TOC | TableOfContents | May be nested, and may be used for lists of figures, tables, etc.
TOCI | TableOfContentsItem | Table of contents (leaf) item
Index | | An index of keywords and topics, usually at the end of the document (text with accompanying Reference content)
NonStruct | NonStructural | non-structural grouping element (element itself not intended to be exported to other formats like HTML, but 'transparent' to its content which is processed normally)
Private | | Content only meaningful to the creator (element and its content not intended to be exported to other formats like HTML)
DocumentFragment | | A partial document fragment (PDF 2.0)
Aside | | Distinct side content (PDF 2.0)
Sub | Subdivision | A subdivision (PDF 2.0)
Title | | Encloses a title of a document or section (PDF 2.0)
FENote | | Used to markup end notes and footnotes (PDF 2.0)

### "Block" elements:

Mnemonic | Tag | Description
Tag | Mnemonic | Description
---------|-----|------------
H | Heading | Nested section heading (not recommended)
H1 - H6 | Heading1 - Heading6 | The title or heading of a section within the text content
P | Paragraph | A distinct section of a piece of writing, usually dealing with a single theme
L | List | A group of similar items that are related to each other. Should include optional Caption, and list items
LI | ListItem | A Single list element. Should contain Lbl and/or LBody
Lbl | Label | Bullet, number, or "dictionary headword"
LBody | ListBody | Description of the item; may have nested lists or other blocks

### "Table" elements:

Tag | Mnemonic | Description
---------|-----|------------
Table | | Content arranged into rows and columns; should either contain TR, or THead, TBody and/or TFoot
TR | TableRow | A single row of cell elements within a table
TH | TableHeader | Description of column contents
TD | TableData | A cell element
THead | TableHead | A row of table headers
TBody |TableBody | Table body; may have more than one per table
TFoot | TableFoot | Table footer row group

### "Inline" elements:

Tag | Mnemonic | Description
---------|-----|------------
Span | | Generic inline content.
Quote | | Inline text referencing content from another source
Note | | End-note or footnote; may have a Lbl (see "block" elements)
Reference | | Content in a document that refers to other content (e.g. page number in an index)
BibEntry | BibliographyEntry | Text referring the user to source of cited text. May have a Lbl (see "block" elements)
Code | | Computer code
Link | | hyperlink; should contain a link annotation
Annot | Annotation | annotation (other than a link)
Ruby | | Chinese/Japanese pronunciation/explanation
RB | RubyBaseText | Ruby base text
RT | RubyText | Ruby annotation text
RP | RubyPunctuation |
Warichu | | Japanese/Chinese longer description
WT | WarichuText
WP | WarichuPunctuation
Emphasis | Em | (PDF 2.0)
Strong | | (PDF 2.0)

### "Illustration" elements (should have Alt and/or ActualText set):

Tag | Mnemonic | Description
---------|-----|------------
Figure | | An image or graphic that is referenced by the text
Formula | | A scientific or mathematical formula element
Form | |  An editable PDF field used to complete a form

### Non-structure tags:

Tag | Mnemonic | Description
---------|-----|------------
Artifact | | Used to mark all content not part of the logical structure
ReversedChars | | Every string of text has characters in reverse order for technical reasons (due to how fonts work for right-to-left languages); strings may have spaces at the beginning or end to separate words, but may not have spaces in the middle

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

Advanced Topics
-----

### Form and Image XObjects

In the simple case, both [PDF::XObject::Form](https://pdf-raku.github.io/PDF-Class-raku/PDF/XObject/Form)'s and [PDF::XObject::Image](https://pdf-raku.github.io/PDF-Class-raku/PDF/XObject/Images)'s are inserted and externally
tagged as an atomic graphical element, typically tagged as `Figure` or `Form`:

```raku
my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";

my $figure = $doc.Figure: $gfx, $img, :position[50, 70], :Alt("A light-bulb");
```

A [PDF::XObject::Form](https://pdf-raku.github.io/PDF-Class-raku/PDF/XObject/Form) may be associated with a document fragment. The
form can then be rendered, and the fragment inserted into the document, by repeatedly calling `do` on the fragment, as demonstrated below:

```raku
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::XObject::Form;
my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

my PDF::Page $page = $pdf.add-page;
$page.graphics: -> $gfx {
   $doc.Header1: $gfx, {
        .say('Header text');
   }

    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my PDF::Tags::Elem $form-frag = $doc.fragment;

    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-frag.Header2: $_, {
            .say: "Tagged XObject header";
        };
        my $p = $form-frag.Paragraph: $_, {
            .say: "Some sample tagged text";
        };
    }

    # multiple rendering of the form, and insertion into the structure tree
    $doc.do($gfx, $form-frag, :position[150, 70]);
    $doc.do($gfx, $form-frag, :position[150, 20]);
}
```
### Links

Links are usually contained in a block element, such as a `Paragraph`. If
the link is internal, it should be further enclosed in a `Reference` element.

Furthermore, if the link is in flowing text, such as a paragraph, the
`mark` method may be needed to mark preceding text, the link, and
following text.

Please see [examples/link.raku](https://github.com/pdf-raku/PDF-Tags-raku/blob/master/examples/link.raku) which demonstrates adding an
tagged internal link to a PDF.

### Graphics Content Tags

As a rule, all content doesn't have to form part of the structure tree, but should be tagged to meet accessibility guidelines.

This sometimes requires tagging of incidental graphics. `PDF::Content` has a `tag()` method for this. The content is be tagged, but does not appear in the content stream.

Some of the commonly used content tags are:

#### Artifact

Artifact content forms part of the visual display, but does not belong in the Structure Tree and is tagged using the `PDF::Content` `tag` method.

For example:
```raku
$gfx.tag: Artifact, {
    .say("Page $page-num", :$font, :position[ 250, 20 ]);
}
```

#### Clipped

A clipped region encompasses additional graphics that are being
used as part of a clipping operation. The clipped area may include graphics that are part of the structure tree. For example:

```raku
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Content::Tag :ContentTags, :ParagraphTags;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $doc = $tags.Document;

$pdf.add-page.graphics: {
    .tag: Clipped, {
        .Rectangle: 100, 100, 125, 20;
        .Clip;
        .EndPath;
        $doc.Paragraph: $_, {
            .say: 'Clip me', :position[98, 98];
        }
    }
}
```
The above example is setting up a clipping sequence. The clipped
text is being inserted as a paragraph in the structure tree.

#### Span

This tag may be used in the structure tree, or at the content level to defined attributes of a graphics sequence. Its usage is similar to the XHTML `span` tag.

```raku
$gfx.tag: Span, :Lang<es-MX>, {
    .say('Hasta la vista', :position[50, 80]);
}
```

It can be used almost anywhere in the structure tree, or at the content level, as above.

### Role Maps

The PDF standard allows user defined tags, which are mapped to
standard tags via a role-map table. `PDF::Tags` supports this
feature, via the `create` `:role-map` option. One declared,
role-map entries, can be called as standard construction
methods:

```raku
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::Page;

enum RoleMap ( :Body<Section>, :Footnote<Note>, :Book<Document> );
constant %role-map = RoleMap.enums.Hash;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf, :%role-map;

my PDF::Tags::Elem $doc = $tags.Book;
my PDF::Page $page = $pdf.add-page;

$page.graphics: -> $gfx {

    $doc.Paragraph: $gfx, {
        .say: 'Some body text¹', :position[50, 150];
    };

    $doc.Footnote: $gfx, {
        .say: '¹With a foot-note', :position[50, 20];
    };

}

```

### Tagging and Metadata

If a PDF document is tagged for accessibility, additional metadata usually also needs to be set-up; typically `Title`, `Author`, `Subject`, `Keywords` and language. For example:

```raku
use PDF::API6;
use PDF::Info;
my PDF::API6 $pdf .= open: "/tmp/synopsis.pdf";

my PDF::Info $info = $pdf.Info //= {};
$info.Title = 'PDF::Tags README Synopsis';
$info.Subject = 'Sample Output PDF';
$info.Author = 'David Warring';
$info.Keywords = 'accessibility,pdf,tags';
$pdf.catalog.Lang = 'en';
$pdf.update;
```

Note that `PDF::API6` automatically fills in `Producer`, `Creator` and `CreationDate`.

### Verification

The `pdf-tag-dump.raku` script from the [PDF::Tags::Reader](https://pdf-raku.github.io/PDF-Tags-Reader-raku) module
can be used to view the logical content of PDF files as XML, for example:
```
$ pdf-tag-dump.raku /tmp/synopsis.pdf
```
Produces
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Document SYSTEM "http://pdf-raku.github.io/dtd/tagged-pdf.dtd">
<?xml-stylesheet type="text/css" href="https://pdf-raku.github.io/css/tagged-pdf.css"?>
<Document>
  <H1>
    Marked Level 1 Header
  </H1>
  <P>
    Marked paragraph text
  </P>
  <Figure BBox="0 0 19 19">
  </Figure>
</Document>
```
The XML output from `pdf-tag-dump.raku` includes an [external DtD](http://pdf-raku.github.io/dtd/tagged-pdf.dtd) for basic validation purposes.

For example, it can be piped to `xmllint`, from the `libxml2` package, to check the structure of the tags:

$ pdf-tag-dump.raku /tmp/synopsis.pdf | xmllint --noout --valid -

See Also
------

- [PDF::Tags::Reader](https://pdf-raku.github.io/PDF-Tags-Reader-raku) - for reading PDF files with existing tagged content

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

- Editing. Currently the API doesn't readily support editing tags into existing content. More work is also
needed in the PDF::Content module to support content editing.
