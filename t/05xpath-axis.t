use Test;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;

plan 18;

sub names(@elems) {
    @elems>>.name.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $dom .= read: :$pdf;

is names($dom.find('Document/L')), ['L', 'L'], "child, repeated";
is names($dom.find('Document/L[1]/LI[1]/LBody/ancestor::*')), 'Document L LI', 'ancestor';
is names($dom.find('/Document/L/LI[1]/LBody')), 'LBody LBody', 'child';
is names($dom.find('Document/L/LI[1]/LBody/ancestor::*')), 'Document L LI L LI', 'ancestor';
is names($dom.find('Document/L/LI[1]/LBody/ancestor-or-self::*')), 'Document L LI LBody L LI LBody', 'ancestor-or-self';
is names($dom.find('Document/L/LI[1]/LBody/child::*')), 'Reference P', 'child';
is names($dom.find('Document/L/LI[1]/LBody/*')), 'Reference P', 'child abbreviated';
is names($dom.find('Document/L/LI[1]/LBody/descendant::*')), 'Reference Link P Code', 'descendant';
is names($dom.find('Document/L/LI[1]/LBody/descendant-or-self::*')), 'LBody Reference Link LBody P Code', 'descendant-or-self';
is names($dom.find('/Document/H1[last()]/following::*')), 'P', 'following';
my $li = $dom.first('Document/L[1]/LI[2]');
my $lbl = $li.first('Lbl');
my $lbody = $li.first('LBody');
is names($lbl.find('following-sibling::*')), 'LBody', 'following-sibling';
is names($lbody.find('/Document/L[1]/LI[1]/LBody/preceding::*')), 'Lbl', 'preceding';
is names($lbody.find('preceding-sibling::*')), ['Lbl'], 'preceding-sibling';
is names($lbody.find('self::*')), ['LBody'], 'self';
is names($lbody.find('.')), ['LBody'], 'self (abbreviated)';
is names($lbody.find('parent::*')), ['LI'], 'parent';
is names($lbody.find('..')), ['LI'], 'parent (abbreviated)';
is names($lbody.find('.././*')), ['Lbl', 'LBody'], 'chained (parent/self/child)';

done-testing;
