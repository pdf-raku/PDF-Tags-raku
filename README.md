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

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
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

# PDF::Class imports
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
    $doc.add-kid(Figure).do($gfx, $img);

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

    # create XObject form with unparented marked content
    my  PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        .mark: Header2, { .say: "Tagged XObject header", :font($header-font), :$font-size};
        .mark: Paragraph, { .say: "Some sample tagged text", :font($body-font), :$font-size};
    }

    # render the form. Inline its marked content
    $doc.add-kid(Form).do: $gfx, $form, :position[150, 70];
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
- [PDF::Tags::Mark](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Mark.md) - Leaf content marker node
- [PDF::Tags::Text](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/Text.md) - Text content node
- [PDF::Tags::ObjRef](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/ObjRef.md) - A reference to a PDF object (PDF::Annot, PDF::Field or PDF::XObject)
- [PDF::Tags::XML-Writer](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/XML-Writer.md) - XML Serializer
- [PDF::Tags::XPath](https://github.com/p6-pdf/PDF-Tags-raku/blob/master/doc/Tags/XPath.md) - XPath evaluation context

Scripts in this Distribution
------

##### `pdf-tag-dump.p6 --include=XPath --omit=tag --password=Xxxx --max-depth=n --marks --/render --/atts --debug t/pdf/tagged.pdf`
