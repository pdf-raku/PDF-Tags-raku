use Test;
use PDF::DOM;
use PDF::DOM::Elem;
use PDF::DOM::Root;
use PDF::Class;

plan 8;

sub tags(@elems) {
    [@elems>>.tag];
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom .= new: :$pdf;
my PDF::DOM::Root $root = $dom.root;

for $root.find('Document') -> $elem {
    isa-ok($elem, PDF::DOM::Elem);
    is $elem.tag, 'Document';
}

is tags($root.find('Document/H1/*')), ['Span' xx 5];
is tags($root.find('Document/H1/*[1]')), ['Span'];
is tags($root.find('Document/L/LI[1]/*')), ['Lbl', 'LBody'];

my $li = $root.first('Document/L/LI[1]');
is tags($li.find('*')), ['Lbl', 'LBody'], 'relative search';
is tags($li.find('/*')), ['Document'], 'absolute search';
is tags($li.find('LBody/Reference/Link/*')), ['#ref', 'Link'];

done-testing;
