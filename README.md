PDF-Tags-raku (under construction)
============

A small DOM-like API for the navigation of PDF tagged content;
read and creation of tagged content with simple XPath queries and basic XML serialization.

SYNOPSIS
--------

### Reading

```
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;

my PDF::Class $pdf .= open: "t/pdf/tagged.pdf";
my PDF::Tags $tags .= read: :$pdf;
my PDF::Tags::Elem $doc = $tags[0];
say $doc.tag; # Document

# DOM traversal
for $doc.kids {
    say .tag; # L, P, H1, P ...
}

# XPath navigation
my @tags = $doc.find('Document/L/LI[1]/LBody//*')>>.tag;
say @tags.join(','); # Reference,P,Code

# XML Serialization
say $doc.xml;

```

### Writing
```
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags;
use PDF::Tags;
use PDF::Tags::Elem;

# PDF::Class
use PDF::Class;
use PDF::Annot;
use PDF::XObject::Image;
use PDF::XObject::Form;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $doc = $tags.add-kid(Document);

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {

    $doc.add-kid(Header1).mark: $gfx, {
        .say('Marked Level 1 Header',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    $doc.add-kid(Paragraph).mark: $gfx, {
        .say('Marked paragraph text', :position[50, 100], :font($body-font), :font-size(12));
    }

    # add a marked image
    my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
    $doc.add-kid(Figure, :Alt('Incandescent apparatus').do($gfx, $img);

    # add a marked link annotation
    my PDF::Annot $link = PDF::COS.coerce: :dict{
        :Type(:name<Annot>),
        :Subtype(:name<Link>),
        :Rect[71, 717, 190, 734],
        :Border[16, 16, 1, [3, 2]],
        :Dest[ $page, :name<FitR>, -4, 399, 199, 533 ],
        :P($page),
    };

    $doc.add-kid(Link).reference($gfx, $link);

    # tagged XObject Form
    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my $form-elem = $doc.add-kid(Form);
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.add-kid(Header2).mark: $_, { .say: "Tagged XObject header", :font($header-font), :$font-size};
        $form-elem.add-kid(Paragraph).mark: $_, { .say: "Some sample tagged text", :font($body-font), :$font-size};
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

PDF tagging may also assist PDF readers and other automated tools in reading PDF
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

- [PDF::Tags](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags.md) - Tagged PDF root node
- [PDF::Tags::Elem](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Elem.md) - Structure Tree descendant node
- [PDF::Tags::Node](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Node.md) - Abstract node
- [PDF::Tags::Node::Parent](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Node/Parent.md) - Abstract parent node
- [PDF::Tags::Mark](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Mark.md) - Leaf content marker node
- [PDF::Tags::Text](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Text.md) - Text content node
- [PDF::Tags::ObjRef](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/ObjRef.md) - A reference to a PDF object (PDF::Annot, PDF::Field or PDF::XObject)
- [PDF::Tags::XML-Writer](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/XML-Writer.md) - XML Serializer
- [PDF::Tags::XPath](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/XPath.md) - XPath evaluation context

Scripts in this Distribution
------

##### `pdf-tag-dump.p6 --select=XPath --omit=tag --password=Xxxx --max-depth=n --marks --/atts --/style --debug t/pdf/tagged.pdf`

Todo
---

- Complete POD
- Release (CPAN)

Further Work
----

- Type-casting of PDF::StructElem.A to roles; as per 14.8.5. Possibly belongs in PDF::Class, however slightly complicated by the need to apply role-mapping.

- Develop a tag/accessibility checker. A low-level sanity checker that a tagged PDF is PDF/UA compliant `pdf-tag-checker.raku --ua`. See https://www.pdfa.org/wp-content/uploads/2014/06/MatterhornProtocol_1-02.pdf. Accessibility/UA compliance is probably the most common goal of tagging a PDF.

- Editing. Currently the API primarily runs in `create` or `read` modes, but doesn't readily support editing tags into existing content. More work is also
needed in the PDF::Content module to support content editing.
