use Test;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;

plan 9;

sub names(@elems) {
    [@elems>>.name];
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $dom .= read: :$pdf;

for $dom.find('Document') -> $elem {
    isa-ok($elem, PDF::Tags::Elem);
    is $elem.name, 'Document', 'find root element';
}

is names($dom.find('Document/H1[position()]')), ['H1' xx 5], 'path expression';

is names($dom.find('Document/H1[position() > 3]')), ['H1' xx 2], 'path expression';

is names($dom.find('Document/H1[position() > 3 and position() < 5]')), ['H1' xx 1], 'path expression';

is names($dom.find('Document/H1[position() >= 3 and position() <= 5]')), ['H1' xx 3], 'path expression';

is names($dom.find('Document/H1[position() = 2 or position() = 4]')), ['H1' xx 2], 'path expression';

is names($dom.find('Document/H1[(((position() > 3)) or position() < 5)]')), ['H1' xx 5], 'path expression';

is names($dom.find('Document/H1[position() !=4 ]')), ['H1' xx 4], 'path expression';

done-testing;
