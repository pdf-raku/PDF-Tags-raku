use Test;
use PDF::DOM;
use PDF::DOM::Elem;
use PDF::Class;

plan 12;

sub tags(@elems) {
    @elems>>.tag.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom .= new: :$pdf;

for $dom.find('Document') -> $elem {
    isa-ok($elem, PDF::DOM::Elem);
    is $elem.tag, 'Document', 'find root element';
}

is tags($dom.find('Document/H1/*')), 'Span Span Span Span Span', 'path expression';
is tags($dom.find('Document/H1/*[1]')), 'Span Span Span Span Span', 'position';
is tags($dom.find('Document/L/LI[1]/*')), 'Lbl LBody Lbl LBody', 'position/child';
is tags($dom.find('Document/L/LI[1]/LBody//*')), 'Reference Link Link P P Code Code', 'descendants';
is tags($dom.find('Document/L/child::LI[position()=1]/*')), 'Lbl LBody Lbl LBody', 'explicit (axis and position)';

is tags($dom.find('Document/L[1]/LI[1] | Document/H1[1]')), 'LI H1', 'union';

my $li = $dom.first('Document/L/LI[1]');
is tags($li.find('*')), 'Lbl LBody', 'relative search';
is tags($li.find('/*')), 'Document', 'absolute search';
is tags($li.find('LBody/Reference/Link/*')), 'Link', 'tagged content';
is $li.text, '• NAME ';

done-testing;
