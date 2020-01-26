PDF-DOM-raku (under construction)
============

A small DOM-like API for the navigation of PDF tagged content; simple XPath queries.

SYNOPSIS
--------

```
use PDF::Class;
use PDF::DOM;
use PDF::DOM::Elem;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::DOM $dom .= new: :$pdf;
my PDF::DOM::Elem ($doc) = $dom.root[0];
say $doc.tag, 'Document';

for $doc.kids {
    say .tag;
}

# XPath navigation
my @tags = $root.find('Document/L/LI[1]/LBody//*')>>.tag
say @tags.join(','); # Reference,Link,Link
```

Node Types
----------

- `PDF::DOM::Root` - Structure Tree root element
- `PDF::DOM::Elem` - A 'Structure Tree' Item
- `PDF::DOM::Tag` - A content-mapped item
- `PDF::DOM::Text` - Document Text
- `PDF::DOM::ObjRef` - A reference to a PDF::Class object (such as PDF::Annot or PDF::Field)


Scripts in this Distribution
------

##### `pdf-dom-dump.p6 --path=XPath --password=Xxxx --page=i --max-depth=j --skip --/render --/atts --debug t/pdf/tagged.pdf

