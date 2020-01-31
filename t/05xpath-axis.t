use Test;
use PDF::Tagged;
use PDF::Tagged::Elem;
use PDF::Tagged::Root;
use PDF::Class;

plan 18;

sub tags(@elems) {
    @elems>>.tag.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tagged $dom .= new: :$pdf;

is tags($dom.find('Document/L')), ['L', 'L'], "child, repeated";
is tags($dom.find('Document/L[1]/LI[1]/LBody/ancestor::*')), 'Document L LI', 'ancestor';
is tags($dom.find('/Document/L/LI[1]/LBody')), 'LBody LBody', 'child';
is tags($dom.find('Document/L/LI[1]/LBody/ancestor::*')), 'Document L LI L LI', 'ancestor';
is tags($dom.find('Document/L/LI[1]/LBody/ancestor-or-self::*')), 'Document L LI LBody L LI LBody', 'ancestor-or-self';
is tags($dom.find('Document/L/LI[1]/LBody/child::*')), 'Reference P', 'child';
is tags($dom.find('Document/L/LI[1]/LBody/*')), 'Reference P', 'child abbreviated';
is tags($dom.find('Document/L/LI[1]/LBody/descendant::*')), 'Reference Link Link P P Code Code', 'descendant';
is tags($dom.find('Document/L/LI[1]/LBody/descendant-or-self::*')), 'LBody Reference Link Link LBody P P Code Code', 'descendant-or-self';
is tags($dom.find('/Document/H1[last()]/following::*')), 'P P', 'following';
my $li = $dom.first('Document/L[1]/LI[2]');
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
