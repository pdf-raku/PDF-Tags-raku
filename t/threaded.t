use v6;
use Test;
plan 1;

# Singler threaded construction
# Precursor to t/threads.t, which does similar, but in parallel

use PDF::Content::FontObj;
use PDF::Content::PageTree;
use PDF::Content::Tag :StructureTags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::Class;
use PDF::Page;
use PDF::Annot;
use PDF::XObject::Image;
use PDF::XObject::Form;

# up-font creation of PDF and font resources
my PDF::Class $pdf .= new;
my PDF::Content::FontObj $font = $pdf.core-font: :family<Helvetica>;
my PDF::Content::FontObj $hdr-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;

my PDF::Tags $tags .= create: :$pdf;
my @page-frags = (1..30).map: { PDF::Content::PageTree.pages-fragment() }
my @struct-frags = (1..30).map: { $tags.fragment(Division) };

(1..30).race(:batch(1)).map: -> $chap-num {
    # create a multi-page fragment for later assembly
    my PDF::Content::PageTree $pages = @page-frags[$chap-num-1];
    # also a chapter tag for later assembly
    my PDF::Tags::Elem $div = @struct-frags[$chap-num-1];
    my PDF::Page $page = $pages.add-page;
    my $p2;

    $page.graphics: -> $gfx {
        $div.Header1: $gfx, {
            .say("Chapter $chap-num",
                 :font($hdr-font),
                 :font-size(16),
                 :position[50, 640]);
        }
        $div.Paragraph: $gfx, {
            .say("This para contained on first page of chapter $chap-num.",
                 :$font,
                 :font-size(12),
                 :position[50, 620]);
        };

        $p2 = $div.Paragraph: $gfx, {
            .say("This para started on first page of chapter $chap-num...",
                 :$font,
                 :font-size(12),
                 :position[50, 600]);
        };
    }

    $page = $pages.add-page;
    $page.graphics: -> $gfx {
        $p2.mark: $gfx, {
        .say("...and finished on second page of chapter $chap-num",
             :$font,
             :font-size(12),
             :position[50, 620]);
        }
    };
    $page.finish;
}

# top-down creation of PDF struct tree
my PDF::Tags::Elem $doc = $tags.Document;

# final sequential assembly of structural sub-trees.
$pdf.Pages.add-pages($_) for @page-frags;
$doc.add-kid(:node($_)) for @struct-frags;

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM.basename.fmt('%-16.16s');

mkdir 'tmp';
lives-ok { $pdf.save-as: "tmp/threaded.pdf", :!info; }

done-testing;
