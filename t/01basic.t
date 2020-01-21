use Test;
use PDF::DOM;
use PDF::DOM::Root;
use PDF::Class;

plan 7;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom;
my PDF::DOM::Root $root;

lives-ok { $dom .= new: :$pdf;};
lives-ok { $root = $dom.root };

my $doc = $root[0];
is $doc.tag, 'Document';
my $node = $doc[2];
is $node.tag, 'H1';
is-deeply $doc[0].kids>>.tag.join(','), ('LI' xx 5).join(',');
is $node.parent.tag, 'Document';
is $node.root.tag, '#root';

done-testing;