=begin pod
This example demonstrates adding a paragraph with an embedded link.
=end pod

use PDF::Tags;
use PDF::Tags::Elem;

# PDF::API6
use PDF::API6;
use PDF::Annot;
use PDF::Annot::Link;
use PDF::Destination :Fit, :DestRef;
use PDF::XObject::Image;
use PDF::XObject::Form;
use PDF::Content::Color :&color, :&ColorName;

my PDF::API6 $pdf .= new;
my PDF::Tags $tags .= create: :$pdf;
# create the document root
my PDF::Tags::Elem $doc = $tags.Document;

my $page = $pdf.add-page;
my $header-font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

$pdf.add-page; # blank second page, as a target

$page.graphics: -> $gfx {

    enum <x0 y0 x1 y1>;
    my @rect;
    # start the paragraph adding text preceding the link
    my  PDF::Tags::Elem $para = $doc.Paragraph: $gfx, {
        @rect = .print: 'This is a ', :position[20, 400];
    }

    # by convention, internal links should be contained in a Reference tag
    my $ref = $para.Reference;

    # Use PDF::API6 to create the link
    my $link-text ='Sample Annot';
    my DestRef $destination = $pdf.destination( :name<sample-annot>, :page(2), :fit(FitWindow) );
    my PDF::Action $action = PDF::API6.action: :$destination;
    my PDF::Annot::Link $href = $pdf.annotation: :$page, :$action, :content($link-text), :Border[0,0,0], :rect[0 xx 4];

    # by convention Link tags contain a reference to the link and the
    # associated content. Create the link and add marked content to it.
    my $link = $ref.Link($gfx, $href);
    $link.mark: $gfx, {
        .Save;
        .FillColor = color Blue;
        @rect = .print: $link-text, :position[@rect[x1], @rect[y0]];
        # set the position of the annotation to match the link text
        @rect = .base-coords: @rect;
        $href.rect = @rect;
        .Restore;
    }

    # Add further trailing text to the paragraph.
    $para.mark: $gfx, {
        .say: ' in a paragraph.', :position[@rect[x1], @rect[y0]];
    }
}

$pdf.save-as: "link.pdf"
