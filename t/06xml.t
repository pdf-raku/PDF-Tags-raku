use Test;
use PDF::DOM;
use PDF::Class;

plan 2;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::DOM $dom .= new: :$pdf;

is-deeply $dom.xml.lines.head(3), (
    '<Document>',
    '  <L ListNumbering="Disc">',
    '    <LI>');

is-deeply $dom.root[0][0][0][1][0].xml.lines, (
    '<Reference>',
    '  <Link TextDecorationType="Underline">',
    '    <Link>NAME </Link>',
    '  </Link>',
    '</Reference>',
);

done-testing;
