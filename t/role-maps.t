use v6;
use Test;
plan 10;

use PDF::Content::FontObj;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::Class;
use PDF::Page;
use PDF::Annot;
use PDF::XObject::Image;
use PDF::XObject::Form;

enum RoleMap ( :Body<Sect>, :Footnote<Note>, :Book<Document> );
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

    is $page.struct-parent, 0, '$page.struct-parent';
    my $para = $doc.Paragraph: $gfx, {
        .say: 'Some body text', :position[50, 100], :font($body-font), :font-size(12);
    };
    is $para.name, 'P', 'outer tag name';
    is $para.kids[0].name, 'P', 'inner tag name';

}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'H1,P';

lives-ok { $pdf.save-as: "t/role-maps.pdf", :!info }; 

done-testing;
