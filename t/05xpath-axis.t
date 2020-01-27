use Test;
use PDF::DOM;
use PDF::DOM::Elem;
use PDF::DOM::Root;
use PDF::Class;

plan 15;

sub tags(@elems) {
    [@elems>>.tag];
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom .= new: :$pdf;
my PDF::DOM::Root $root = $dom.root;

is tags($root.find('Document/L/LI[1]/LBody/ancestor::*')), ['LI', 'L', 'Document'], 'ancestor';
is tags($root.find('Document/L/LI[1]/LBody/ancestor-or-self::*')), ['LBody', 'LI', 'L', 'Document'], 'ancestor-or-self';
is tags($root.find('Document/L/LI[1]/LBody/child::*')), ['Reference'], 'child';
is tags($root.find('Document/L/LI[1]/LBody/*')), ['Reference'], 'child abbreviated';
is tags($root.find('Document/L/LI[1]/LBody/descendant::*')), ['Reference', 'Link', 'Link'], 'descendant';
is tags($root.find('Document/L/LI[1]/LBody/descendant-or-self::*')), ['LBody', 'Reference', 'Link', 'Link'], 'descendant-or-self';
my $li = $root.first('Document/L/LI[2]');
my $lbl = $li.first('Lbl');
my $lbody = $li.first('LBody');
is tags($lbl.find('following::*')), ['LBody', 'Reference', 'Link', 'Link'], 'following';
is tags($lbl.find('following-sibling::*')), ['LBody'], 'following-sibling';
is tags($lbody.find('preceding::*')), ['Lbl', 'Lbl'], 'preceding';
is tags($lbody.find('preceding-sibling::*')), ['Lbl'], 'preceding-sibling';
is tags($lbody.find('self::*')), ['LBody'], 'self';
is tags($lbody.find('.')), ['LBody'], 'self (abbreviated)';
is tags($lbody.find('parent::*')), ['LI'], 'parent';
is tags($lbody.find('..')), ['LI'], 'parent (abbreviated)';
is tags($lbody.find('.././*')), ['Lbl', 'LBody'], 'chained (parent/self/child)';

done-testing;
