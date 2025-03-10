use v6;
use Test;
plan 9;

use PDF::Content::FontObj;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Class;
use PDF::Page;
use PDF::COS::Name;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document: :Lang<en-NZ>;
my $lang = $doc.Lang;
is $doc.Lang, 'en-NZ';

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
    my  $p = $doc.Paragraph;
    $p.mark: $gfx, :Lang<en>, {
        .text: {
            .print: "content tagged english.", :position[50, 83];
        }
    }
    my PDF::Tags::Mark:D $mark = $p.kids[0];
    is $mark.attributes<Lang>, 'en';
    is $mark.xml.chomp, '<Span Lang="en">content tagged english.</Span>';
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'H1,P,P';

lives-ok { $pdf.save-as: "t/attributes.pdf", :!info; }

done-testing;
