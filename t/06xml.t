use Test;
use PDF::Tags;
use PDF::Class;
use PDF::Tags::XML-Writer;

plan 3;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");
my PDF::Tags $dom .= read: :$pdf;

is-deeply $dom.root[0].xml.lines.head(3), (
    '<Document>',
    '  <L ListNumbering="Disc">',
    '    <LI>');

is-deeply $dom.root.xml(:root-tag<Docs>).lines.head(6), (
    '<?xml version="1.0" encoding="UTF-8"?>',
    PDF::Tags::XML-Writer.new.css,
    '<Docs>',
    '  <Document>',
    '    <L ListNumbering="Disc">',
    '      <LI>');

is-deeply $dom.root[0][0][0][1][0].xml.lines, (
    '<Reference>',
    '  <Link TextDecorationType="Underline">',
    '    NAME ',
    '  </Link>',
    '</Reference>',
);

done-testing;
