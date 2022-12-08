use v6;
use Test;
plan 11;

use PDF::Content::FontObj;
use PDF::Content::Tag :Tags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::Page;

enum RoleMap ( :Body<Section>, :Footnote<Note>, :Book<Document> );
constant %role-map = RoleMap.enums.Hash;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf, :%role-map;

my PDF::Tags::Elem $doc = $tags.Book;
is $doc.name, 'Document';
is $doc.attributes<role>, 'Book';
is $doc.cos.S, 'Book';

my PDF::Content::FontObj $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my PDF::Content::FontObj $body-font = $pdf.core-font: :family<Helvetica>;

my PDF::Page $page = $pdf.add-page;

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header = $doc.Header1: $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    };

    is $header.name, 'H1', 'parent elem name';
    is $header.text, "Header text\n", '$.ActualText()';

    my $para = $doc.Paragraph: $gfx, {
        .say: 'Some body text¹²', :position[50, 100], :font($body-font), :font-size(12);
    };
    my $fn1 = $doc.Footnote: $gfx, {
        .print: '¹With a foot-note', :position[50, 50];
    };
    
    is $fn1.name, 'Note';
    is $fn1.attributes<role>, 'Footnote';

    my $fn2 = $doc.add-kid: :name<Footnote>, $gfx, {
        .print: '²And another foot-note', :position[50, 50];
    };
    is $fn2.name, 'Note';
    is $fn2.attributes<role>, 'Footnote';
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'H1,P,Note,Note';

lives-ok { $pdf.save-as: "t/role-maps.pdf", :!info }; 

done-testing;
