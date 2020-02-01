use Test;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Root;
use PDF::Class;

plan 11;

sub tags(@elems) {
    @elems>>.tag.join(' ');
}

my PDF::Class $pdf .= open("t/pdf/tagged.pdf");

my PDF::Tags $dom .= new: :$pdf;

is tags($dom.find('Document/H1/*[1]')), 'Span Span Span Span Span';
is tags($dom.find('Document/H1[1]/*[1]/node()')), 'Span';
is tags($dom.find('Document/H1/*[1]/*/*')), [];
is tags($dom.find('Document/H1[1]/*[1]/*/node()')), '#text';
is tags($dom.find('Document/H1[1]/*[1]/*/text()')), '#text';
is $dom.first('Document/H1/*[1]/*').text(), 'NAME ';
is $dom.first('Document/H1/*[1]/*/text()').text(), 'NAME ';

my $link = $dom.first('Document/L[1]/LI[1]/LBody/Reference/Link');
is tags([$link]), 'Link';
is tags($link.find('*')), 'Link';
is tags($link.find('text()')), '';
is tags($link.find('node()')), '#ref Link';

done-testing;
