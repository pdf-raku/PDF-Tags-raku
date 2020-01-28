use Test;
use PDF::DOM;
use PDF::DOM::Root;
use PDF::Class;

plan 6;

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom;

lives-ok { $dom .= new: :$pdf;};

my $doc = $dom[0];
is $doc.tag, 'Document';
my $node = $doc[2];
is $node.tag, 'H1';
is-deeply $doc[0].kids>>.tag.join(' '), 'LI LI LI LI LI';
is $node.parent.tag, 'Document';
is $dom.tag, '#root';

done-testing;