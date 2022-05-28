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

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;

my PDF::Content::FontObj $font = $pdf.core-font: :family<Helvetica>;
my PDF::Content::FontObj $hdr-font = $pdf.core-font: :family<Helvetica>, :weight<bold>;

my @frags = (1..10).map: -> $chap-num {
    # create a multi-page fragment for later assembly
    my PDF::Content::PageTree $pages .= pages-fragment;
    # also a chapter tag for later assembly
    my PDF::Tags::Elem $frag = $tags.fragment(Division);
    my PDF::Page $page = $pages.add-page;
    my $p2;

    $page.graphics: -> $gfx {
        $frag.Header1: $gfx, {
            .say("Chapter $chap-num",
                 :font($hdr-font),
                 :font-size(16),
                 :position[50, 640]);
        }
        $frag.Paragraph: $gfx, {
            .say("This para contained on first page of chapter $chap-num.",
                 :$font,
                 :font-size(12),
                 :position[50, 620]);
        };

        $p2 = $frag.Paragraph: $gfx, {
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

    %(:$pages, :$frag);
}

my $doc = $tags.Document;

# final assembly of the document

for @frags {
    $pdf.Pages.add-pages: .<pages>;
    $doc.add-kid: :node(.<frag>);
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as: "t/fragments.pdf", :!info; }

done-testing;
