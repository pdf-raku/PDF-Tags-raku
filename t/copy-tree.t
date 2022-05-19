use v6;
use Test;
plan 4;

use lib 't';
use PDF::Class;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::XObject;

my PDF::Class $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $pdf.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header;
    my PDF::Tags::Mark $mark;

    $header = $doc.Header1;
    $mark = $header.mark: $gfx, {
        .print('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }
    my  PDF::XObject $Stm = $page.xobject-form: :BBox[0, 0, 200, 50];

    is $mark.xml().trim, 'Header text';
    is $header.text, "Header text";
    is-deeply $header.xml.lines, ('<H1>', '  Header text', '</H1>');
    my $copy = $header.copy-tree(:$Stm, :parent($doc));
    is-deeply $copy.xml.lines, ('<H1>', '  Header text', '</H1>');
}

done-testing;
