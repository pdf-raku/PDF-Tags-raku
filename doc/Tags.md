NAME
====

PDF::Tags - Tagged PDF root node

SYNOPSIS
========

``` use PDF::Class; use PDF::Tags; use PDF::Tags::Elem;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf"); my PDF::Tags $tags .= read: :$pdf; my PDF::Tags::Elem $doc = $tags[0]; ```

