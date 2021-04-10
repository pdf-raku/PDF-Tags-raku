use v6;
use Test;
plan 16;

use PDF::Class;
use PDF::Content::Tag :ParagraphTags, :InlineElemTags, :IllustrationTags, :StructureTags;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Mark;
use PDF::Tags::ObjRef;
use PDF::Annot;
use PDF::XObject::Image;
use PDF::XObject::Form;

# ensure consistant document ID generation
srand(123456);

my PDF::Class $pdf .= new;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.add-kid: :name(Document);

$page.graphics: -> $gfx {
    my PDF::Tags::Elem $header;
    my PDF::Tags::Mark:D $mark = $doc.Header1( $gfx, {
        .say('Header text',
             :font($header-font),
             :font-size(15),
             :position[50, 120]);
    });

    is $mark.name, 'H1', 'mark tag name';
    is $mark.mcid, 0, 'mark tag mcid';
    is $mark.parent.name, 'H1', 'parent elem name';
    is $mark.parent.ActualText, "Header text\n", '$.ActualText()';

    is $page.struct-parent, 0, '$page.struct-parent';
    is-deeply $tags.parent-tree[0][0], $mark.parent.cos, 'parent-tree entry';

    $mark = $doc.Paragraph( $gfx, {
        .say: 'Some body text', :position[50, 100], :font($body-font), :font-size(12);
    });
    is $mark.name, 'P', 'inner tag name';
    is $mark.parent.name, 'P', 'outer tag name';

    my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";

    my $figure = $doc.Figure: :Alt("A light-bulb");
    $figure.do: $gfx, $img, :position[50, 70];
    is $img.struct-parent, 1, '$img.struct-parent';
    my PDF::Tags::ObjRef $ref = $figure.kids[0];
    ok $ref.value === $img, '$ref.value';

    $doc.Caption( $gfx, {
        .say: "Eureka!", :position[40, 60];
    });

    my PDF::Annot $annot .= COERCE: {
        :Type(:name<Annot>),
        :Subtype(:name<Link>),
        :Rect[71, 717, 190, 734],
        :Border[16, 16, 1, [3, 2]],
        :Dest[ $page, :name<FitR>, -4, 399, 199, 533 ],
        :P($page),
    };

    my PDF::Tags::Elem $link;
    lives-ok { $link = $doc.Link($gfx, $annot); }, 'add reference';
    # inspect COS objects
    my PDF::OBJR $obj-ref = $link.kids[0].cos;
    my $cos-obj = $obj-ref.object;
    isa-ok $cos-obj, "PDF::Annot::Link", '$obj-ref.object';
    is $cos-obj.struct-parent, 2, '$obj-ref.object.struct-parent';
    is-deeply $tags.parent-tree[2], $link.cos, 'parent-tree entry'; 

    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my PDF::Tags::Elem $form-elem = $doc.Form;
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.Header2( $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size;
        });
        $form-elem.Paragraph($_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size;
        });
    }

    $form-elem.do($gfx, :position[150, 70]);
    $form-elem.do($gfx, :position[150, 20]);
}

lives-ok { $pdf.save-as: "t/write-tags.pdf", :!info; }

$pdf .= open: "t/write-tags.pdf";
$tags .= read: :$pdf;
is $tags.find('Document//*')>>.name.join(','), 'H1,P,Figure,Caption,Link,Form,H2,P,Form,H2,P';

done-testing;
