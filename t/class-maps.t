use v6;
use Test;
plan 3;

use PDF::Content::FontObj;
use PDF::Content::Tag :Tags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::Page;
use PDF::COS::Name;
sub prefix:</>($s) { PDF::COS::Name.COERCE($s) };

enum ClassMap ( :Normal{
                  :StartIndent(10),
                  :EndIndent(20),
                  :TextAlign(/'Start'),
                 }
               );
constant %class-map = ClassMap.enums.Hash;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf, :%class-map;

my PDF::Tags::Elem $doc = $tags.Document;

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

    my $para = $doc.Paragraph: $gfx, :class<Normal>, {
        .say: 'Some body text¹²', :position[50, 100], :font($body-font), :font-size(12);
    };

    is-deeply $para.attributes, %class-map<Normal>;
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM.basename.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'H1,P';

lives-ok { $pdf.save-as: "t/class-maps.pdf", :!info }; 

done-testing;
