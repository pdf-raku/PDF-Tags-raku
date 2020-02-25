PDF-Tags-raku (under construction)
============

A small DOM-like API for the navigation of PDF tagged content; simple XPath queries.

SYNOPSIS
--------

```
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags $dom .= new: :$pdf;
my PDF::Tags::Elem $doc = $dom.root[0];
say $doc.tag; # Document

for $doc.kids {
    say .tag;
}

# XPath navigation
my @tags = $root.find('Document/L/LI[1]/LBody//*')>>.tag
say @tags.join(','); # Reference,P,Code
```

Node Types
----------

- `PDF::Tags::Root` - Structure Tree root element
- `PDF::Tags::Elem` - A 'Structure Tree' Item
- `PDF::Tags::Mark` - A content marker item
- `PDF::Tags::Text` - Document Text
- `PDF::Tags::ObjRef` - A reference to a PDF::Class object (such as PDF::Annot or PDF::Field)


Scripts in this Distribution
------

##### `pdf-tag-dump.p6 --include=XPath --exclude=XPath --password=Xxxx --max-depth=n --marks --/render --/atts --debug t/pdf/tagged.pdf`
