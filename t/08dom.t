use Test;
use PDF::Tags;
use PDF::Class;
use  PDF::Tags::XML-Writer;

plan 15;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags $dom .= read: :$pdf;
my $doc = $dom[0];
is $doc.name, 'Document', 'Document root';

is $doc[0].name, 'L', 'AT-KEY';

is $doc.keys.sort.join(','), 'H1,H2,L,P', 'Document root keys';
my @L = $doc<L>;
is +@L, 2;
my $L0 := @L[0];
is $L0.name, 'L';
is $L0.keys.sort.join(','), '@ListNumbering,@O,LI';
is $L0<@ListNumbering>, 'Disc';
is $L0<@O>, 'List';
is $L0<LI>[0].name, 'LI';
is $L0<..>[0].name, 'Document';

is $dom<Document/L[1]/LI>[0].name, 'LI';
is $dom<Document/L[1]/@O>[0], 'List';

my $Link = $dom<Document/L/LI[1]/LBody/Reference/Link>[0];
is $Link.name, 'Link';
is $Link<@TextDecorationType>, "Underline";
is $dom<Document/L/LI[1]/LBody/Reference/Link/@TextDecorationType>, 'Underline';

done-testing;
