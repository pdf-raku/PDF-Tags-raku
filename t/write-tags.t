use v6;
use Test;
plan 12;

use lib 't';
use PDF::Class;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::Content::XObject;

# ensure consistant document ID generation
srand(123456);

my PDF::Class $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.add-kid(Document);

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header;
    my PDF::Tags::Mark $mark;

    $header = $doc.add-kid(Header1);
    $mark = $header.mark: $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    }

    is $mark.name, 'H1', 'mark tag name';
    is $mark.mcid, 0, 'mark tag mcid';
    is $mark.parent.name, 'H1', 'parent elem name';

    $mark = $doc.add-kid(Paragraph).mark: $gfx, {
        .say('Some body text', :position[50, 100], :font($body-font), :font-size(12));
    }
    is $mark.name, 'P', 'inner tag name';
    is $mark.parent.name, 'P', 'outer tag name';

    sub outer-rect(*@rects) {
        [
            @rects.map(*[0].round).min, @rects.map(*[1].round).min,
            @rects.map(*[2].round).max, @rects.map(*[3].round).max,
        ]
    }

    my PDF::Content::XObject $img .= open: "t/images/lightbulb.gif";

    my @rect;
    $mark = $doc.add-kid(Figure).mark: $gfx, {
        @rect = outer-rect([
            $gfx.do($img, :position[50, 70]),
            $gfx.say("Eureka!", :tag<Caption>, :position[40, 60]),
            ]);
    }
    $mark.parent.set-bbox($gfx, @rect);
    is-deeply $mark.parent.attributes<BBox>, [40, 60, 81, 89], 'image tag BBox';

    my Hash $link = PDF::COS.coerce: :dict{
        :Type(:name<Annot>),
        :Subtype(:name<Link>),
        :Rect[71, 717, 190, 734],
        :Border[16, 16, 1, [3, 2]],
        :Dest[ $page, :name<FitR>, -4, 399, 199, 533 ],
        :P($page),
    };

    my PDF::Tags::ObjRef $obj-ref;
    lives-ok {$obj-ref = $doc.add-kid(Link).reference($gfx, $link)}, 'add reference';
    # inspect objects
    my $cos-obj = $obj-ref.object;
    isa-ok $cos-obj, "PDF::Annot::Link", '$obj-ref.object';
    is $cos-obj.struct-parent, 0, '$obj-ref.object.struct-parent';
    is-deeply $tags.parent-tree[0], $obj-ref.value, 'parent-tree entry'; 

    my  PDF::Content::XObject $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        .mark: Header1, { .say: "Tagged XObject header", :font($header-font), :$font-size};
        .mark: Paragraph, { .say: "Some sample tagged text", :font($body-font), :$font-size};
    }

    $doc.add-kid(Form).do: $gfx, $form, :marks, :position[150, 70];
}

lives-ok { $pdf.save-as: "t/write-tags.pdf" }

$pdf .= open: "t/write-tags.pdf";
$tags .= read: :$pdf;
is $tags.find('Document//*')>>.name.join(','), 'H1,P,Figure,Link,Form,H1,P';

done-testing;
