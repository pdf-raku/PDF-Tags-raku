use v6;
use Test;
plan 6;

use PDF::Content::FontObj;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::Page;
use PDF::COS::Name;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

my PDF::Page $page = $pdf.add-page;
my PDF::Content::FontObj $header-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;
my PDF::Content::FontObj $body-font = $pdf.core-font: :family<Helvetica>;

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header = $doc.Header1: $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }, :attributes{ :Placement<Block> };
    my $placement = $header.attributes<Placement>;
    is $placement, 'Block';
    my $cos-placement = $header.cos.A<Placement>;
    is $cos-placement, 'Block';
    does-ok $cos-placement, PDF::COS::Name;
    my $owner = $header.cos.A.owner;
    is $owner, 'Layout';

    my $para = $doc.Paragraph: $gfx, {
        .say: 'Some body text', :position[50, 100], :font($body-font), :font-size(12);
    };
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'H1,P';

lives-ok { $pdf.save-as: "t/attributes.pdf", :!info; }

done-testing;
