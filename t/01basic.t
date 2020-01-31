use Test;
use PDF::Tagged;
use PDF::Tagged::Root;
use PDF::Class;

plan 9;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tagged $dom;

lives-ok { $dom .= new: :$pdf;};

my $doc = $dom[0];
is $doc.tag, 'Document';
my $node = $doc[2];
is $node.tag, 'H1';
is-deeply $doc[0].kids>>.tag.join(' '), 'LI LI LI LI LI';
is $node.parent.tag, 'Document';
is $dom.tag, '#root';

is-deeply $doc.keys.sort, ('H1', 'H2', 'L', 'P');
is $doc<H1>[2].tag, 'H1';
is-deeply $doc<L>[0]<LI>[1].keys.sort, ('LBody', 'Lbl');

done-testing;