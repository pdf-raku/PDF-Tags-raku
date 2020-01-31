PDF-Tagged-raku (under construction)
============

A small DOM-like API for the navigation of PDF tagged content; simple XPath queries.

SYNOPSIS
--------

```
use PDF::Class;
use PDF::Tagged;
use PDF::Tagged::Elem;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tagged $dom .= new: :$pdf;
my PDF::Tagged::Elem $doc = $dom.root[0];
say $doc.tag, 'Document';

for $doc.kids {
    say .tag;
}

# XPath navigation
my @tags = $root.find('Document/L/LI[1]/LBody//*')>>.tag
say @tags.join(','); # Reference,Link,Link,P,P,Code,Code
```

Node Types
----------

- `PDF::Tagged::Root` - Structure Tree root element
- `PDF::Tagged::Elem` - A 'Structure Tree' Item
- `PDF::Tagged::Tag` - A content-mapped item
- `PDF::Tagged::Text` - Document Text
- `PDF::Tagged::ObjRef` - A reference to a PDF::Class object (such as PDF::Annot or PDF::Field)


Scripts in this Distribution
------

##### `pdf-tag-dump.p6 --path=XPath --password=Xxxx --max-depth=n --skip --/render --/atts --debug t/pdf/tagged.pdf

