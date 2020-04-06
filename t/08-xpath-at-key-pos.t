use Test;
use PDF::Tags;
use PDF::Class;

plan 20;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags $dom .= read: :$pdf;
my $doc = $dom[0];
is $doc.name, 'Document', 'root element';

is $doc[0].name, 'L', 'AT-POS';
is $doc[1].name, 'P', 'AT-POS';

is $doc.keys.sort.join(','), 'H1,H2,L,P', 'Document root keys';
is $doc<*>.map(*.name).unique.sort.join(','), 'H1,H2,L,P', 'Document XPath children';
is $doc.kids.map(*.name).unique.sort.join(','), 'H1,H2,L,P', 'Document DOM children';
my @L = $doc<L>;
is +@L, 2, 'AT-KEY count';
my $L0 := @L[0];
is $L0.name, 'L', 'AT-KEY element';
is $L0.keys.sort.join(','), '@ListNumbering,@O,LI', 'keys (attributes + elements)';
is $L0<@ListNumbering>, 'Disc', 'AT-KEY attribute';
is $L0<@O>, 'List', 'AT-KEY attribute';
is $L0<LI>[0].name, 'LI', 'AT-KEY child';
is $L0<..>[0].name, 'Document', 'AT-KEY parent';
is $doc<P>[0].name, 'P', 'AT-KEY element';

is $dom<Document/L[1]/LI>[0].name, 'LI', 'path name';
is $dom<Document/L[1]/*>[0].name, 'LI', 'path element';
is $dom<Document/L[1]/@O>[0], 'List', 'path attribute';

my $Link = $dom<Document/L/LI[1]/LBody/Reference/Link>[0];
is $Link.name, 'Link', 'path from document element';
is $Link<@TextDecorationType>, 'Underline', 'attribute relative';
is $dom<Document/L/LI[1]/LBody/Reference/Link/@TextDecorationType>, 'Underline', 'path from root';

done-testing;
