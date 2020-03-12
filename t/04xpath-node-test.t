use Test;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::ObjRef;
use PDF::Tags::Root;
use PDF::Class;

plan 11;

sub names(@elems) {
    @elems>>.name.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $dom .= read: :$pdf;

is names($dom.find('Document/H1/*[1]')), 'Span Span Span Span Span';
is names($dom.find('Document/H1[1]/node()')), 'Span';
is names($dom.find('Document/H1/*[1]/*/*')), [];
is names($dom.find('Document/H1[1]/*/node()')), '#text';
is names($dom.find('Document/H1[1]/*/text()')), '#text';
is $dom.first('Document/H1/*').text(), 'NAME ';
is $dom.first('Document/H1/*/text()').text(), 'NAME ';

my $link = $dom.first('Document/L[1]/LI[1]/LBody/Reference/Link');
is names([$link]), 'Link';
is names($link.find('text()')), '#text';
is names($link.find('node()')), '#ref #text';

my PDF::Tags::ObjRef $ref = $link.first('//object-ref()');
isa-ok $ref.object, 'PDF::Annot', 'object()';

done-testing;
