use Test;
use PDF::DOM;
use PDF::DOM::Elem;
use PDF::DOM::Root;
use PDF::Class;

plan 16;

sub tags(@elems) {
    @elems>>.tag.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::DOM $dom .= new: :$pdf;
my PDF::DOM::Root $root = $dom.root;

is tags($root.find('Document/L')), ['L', 'L'], "child, repeated";
todo "regressions against LibXML XPath", 6;
is tags($root.find('Document/L/LI[1]/LBody/ancestor::*')), 'Document L LI L LI', 'ancestor';
is tags($root.find('Document/L/LI[1]/LBody/ancestor-or-self::*')), 'Document L LI LBody L LI LBody', 'ancestor-or-self';
is tags($root.find('Document/L/LI[1]/LBody/child::*')), 'Reference P', 'child';
is tags($root.find('Document/L/LI[1]/LBody/*')), 'Reference P', 'child abbreviated';
is tags($root.find('Document/L/LI[1]/LBody/descendant::*')), 'Reference Link Link P P Code Code', 'descendant';
is tags($root.find('Document/L/LI[1]/LBody/descendant-or-self::*')), 'LBody Reference Link Link LBody P P Code Code', 'descendant-or-self';
is tags($root.find('/Document/H1[last()]/following::*')), 'P P', 'following';
my $li = $root.first('Document/L[1]/LI[2]');
my $lbl = $li.first('Lbl');
my $lbody = $li.first('LBody');
is tags($lbl.find('following-sibling::*')), 'LBody', 'following-sibling';
is tags($lbody.find('/Document/L[1]/LI[1]/LBody/preceding::*')), 'Lbl Lbl', 'preceding';
is tags($lbody.find('preceding-sibling::*')), ['Lbl'], 'preceding-sibling';
is tags($lbody.find('self::*')), ['LBody'], 'self';
is tags($lbody.find('.')), ['LBody'], 'self (abbreviated)';
is tags($lbody.find('parent::*')), ['LI'], 'parent';
is tags($lbody.find('..')), ['LI'], 'parent (abbreviated)';
is tags($lbody.find('.././*')), ['Lbl', 'LBody'], 'chained (parent/self/child)';

done-testing;
