[[Raku PDF Project]](https://pdf-raku.github.io)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku)

PDF-Tags-raku (**EXPERIMENTAL**)
============

A small DOM-like API for the navigation of tagged PDF files.

This module enables reading and creation of tagged content with simple XPath queries and basic XML serialization.

Synopsis
--------

### Reading

```
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;

my PDF::Class $pdf .= open: "t/pdf/tagged.pdf";
my PDF::Tags $tags .= read: :$pdf;
my PDF::Tags::Elem $dom = $tags[0];
say $dom.name; # Document

# DOM traversal
for $dom.kids {
    say .name; # L, P, H1, P ...
}

# XPath navigation
my @tags = $dom.find('Document/L/LI[1]/LBody//*')>>.name;
say @tags.join(','); # Reference,P,Code

# XML Serialization
say $dom.xml;

```

### Writing
```
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags;
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
my PDF::Tags::Elem $dom = $tags.add-kid: :name(Document);

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {

    $dom.add-kid(:name(Header1)).mark: $gfx, {
        .say('Marked Level 1 Header',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    $dom.add-kid(:name(Paragraph)).mark: $gfx, {
        .say('Marked paragraph text', :position[50, 100], :font($body-font), :font-size(12));
    }

    # add a marked image
    my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
    $dom.add-kid(:name(Figure), :Alt('Incandescent apparatus').do($gfx, $img);

    # add a marked link annotation
    my $destination = $pdf.destination( :page(2), :fit(FitWindow) );
    my PDF::Annot $link = $pdf.annotation: :$page, :$destination, :rect[71, 717, 190, 734];

    $dom.add-kid(:name(Link)).reference($gfx, $link);

    # tagged XObject Form
    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my $form-elem = $dom.add-kid(:name(Form));
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];

        $form-elem.add-kid(:name(Header2)).mark: $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size;
        }

        $form-elem.add-kid(:name(Paragraph)).mark: $_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size;
        }
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

##### `pdf-tag-dump.raku --select=XPath --omit=tag --password=Xxxx --max-depth=n --marks --/atts --/style --debug t/pdf/tagged.pdf`

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

The PDF accessability standard ISO 14289-1 cannot be distributed and needs to be [purchased from ISO](https://www.iso.org/standard/64599.html).

- Editing. Currently the API primarily runs in `create` or `read` modes, but doesn't readily support editing tags into existing content. More work is also
needed in the PDF::Content module to support content editing.
