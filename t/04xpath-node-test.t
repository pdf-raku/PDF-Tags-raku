use Test;
use PDF::DOM;
use PDF::DOM::Elem;
use PDF::DOM::Root;
use PDF::Class;

plan 11;

sub tags(@elems) {
    [@elems>>.tag];
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom .= new: :$pdf;
my PDF::DOM::Root $root = $dom.root;

is tags($root.find('Document/H1/*[1]')), ['Span'];
is tags($root.find('Document/H1/*[1]/node()')), ['Span'];
is tags($root.find('Document/H1/*[1]/*/*')), [];
is tags($root.find('Document/H1/*[1]/*/node()')), ['#text'];
is tags($root.find('Document/H1/*[1]/*/text()')), ['#text'];
is $root.first('Document/H1/*[1]/*').text(), 'NAME ';
is $root.first('Document/H1/*[1]/*/text()').text(), 'NAME ';

my $link = $root.first('Document/L[1]/LI[1]/LBody/Reference/Link');
is tags([$link]), ['Link'];
is tags($link.find('*')), ['Link'];
is tags($link.find('text()')), [];
is tags($link.find('node()')), ['#ref', 'Link'];

done-testing;
