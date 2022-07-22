use v6;
use Test;
plan 2;

use PDF::Content::FontObj;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::Class;
use PDF::Page;
use PDF::Annot;

my PDF::Class $pdf .= new;

my PDF::Page $page = $pdf.add-page;
my PDF::Content::FontObj $font = $pdf.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

my PDF::Tags::Elem $p1 = $doc.Paragraph;
my PDF::Tags::Elem $p2 = $doc.Paragraph;

$page.graphics: -> $gfx {
    $p1.mark: $gfx, {
        .say('This para contained on first page.',
             :$font,
             :font-size(15),
             :position[50, 620]);
    };

    $p2.mark: $gfx, {
        .say('This para started on first page...',
             :$font,
             :font-size(15),
             :position[50, 600]);
    };

}

$page = $pdf.add-page;
$page.graphics: -> $gfx {

    $p2.mark: $gfx, {
        .say('...and finished on second page',
             :$font,
             :font-size(15),
             :position[50, 620]);
    };

}
# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

is $tags.find('Document//*')>>.name.join(','), 'P,P';

lives-ok { $pdf.save-as: "t/span-pages.pdf", :!info; }

done-testing;
