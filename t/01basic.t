use Test;
use PDF::Tags;
use PDF::Tags::Root;
use PDF::Class;

plan 9;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $tags;

lives-ok {$tags .= read: :$pdf;};

my $doc = $tags[0];
is $doc.tag, 'Document';
my $node = $doc[2];
is $node.tag, 'H1';
is-deeply $doc[0].kids>>.tag.join(' '), 'LI LI LI LI LI';
is $node.parent.tag, 'Document';
is $tags.tag, '#root';

is-deeply $doc.keys.sort, ('H1', 'H2', 'L', 'P');
is $doc<H1>[2].tag, 'H1';
is-deeply $doc<L>[0]<LI>[1].keys.sort, ('LBody', 'Lbl');

done-testing;