use Test;
use PDF::Tags;
use PDF::Class;

plan 2;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags $dom .= read: :$pdf;

is-deeply $dom.xml.lines.head(3), (
    '<Document>',
    '  <L ListNumbering="Disc">',
    '    <LI>');

is-deeply $dom.root[0][0][0][1][0].xml.lines, (
    '<Reference>',
    '  <Link TextDecorationType="Underline">',
    '    NAME ',
    '  </Link>',
    '</Reference>',
);

done-testing;
