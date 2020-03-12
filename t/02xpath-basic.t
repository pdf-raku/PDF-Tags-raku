use Test;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;

plan 11;

sub tags(@elems) {
    @elems>>.name.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $dom .= read: :$pdf;

for $dom.find('Document') -> $elem {
    isa-ok($elem, PDF::Tags::Elem);
    is $elem.name, 'Document', 'find root element';
}

is tags($dom.find('Document/H1/*')), 'Span Span Span Span Span', 'path expression';
is tags($dom.find('Document/H1/*[1]')), 'Span Span Span Span Span', 'position';
is tags($dom.find('Document/L/LI[1]/*')), 'Lbl LBody Lbl LBody', 'position/child';
is tags($dom.find('Document/L/LI[1]/LBody//*')), 'Reference Link P Code', 'descendants';
is tags($dom.find('Document/L/child::LI[position()=1]/*')), 'Lbl LBody Lbl LBody', 'explicit (axis and position)';

is tags($dom.find('Document/L[1]/LI[1] | Document/H1[1]')), 'LI H1', 'union';

my $li = $dom.first('Document/L/LI[1]');
is tags($li.find('*')), 'Lbl LBody', 'relative search';
is tags($li.find('/*')), 'Document', 'absolute search';
is $li.text, '• NAME ';

done-testing;
