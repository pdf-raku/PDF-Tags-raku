NAME
====

PDF::Tags - Tagged PDF root node

SYNOPSIS
========

``` use PDF::Content::Tag :ParagraphTags; use PDF::Class; use PDF::Tags; use PDF::Tags::Elem;

# create tags my PDF::Class $pdf .= new;

my $page = $pdf.add-page; my $font = $page.core-font: :family<Helvetica>, :weight<bold>; my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf; my PDF::Tags::Elem $doc = $tags.add-kid(Document);

$page.graphics: -> $gfx { $doc.add-kid(Paragraph).mark: $gfx, { .say('Hello tagged world!', :$font, :font-size(15), :position[50, 120]); } } $pdf.save-as: "t/pdf/tagged.pdf";

# read tags my PDF::Class $pdf .= open: "t/pdf/tagged.pdf"); my PDF::Tags $tags .= read: :$pdf; my PDF::Tags::Elem $doc = $tags[0];

# search tags my PDF::Tags @elems = $tags.find('Document//*'); ```

DESCRIPTION
===========

A tagged PDF contains additional markup information describing the logical document structure.

