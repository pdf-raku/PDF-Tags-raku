[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Elem](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Elem)

class PDF::Tags::Elem
---------------------

represents one node in the structure tree.

Synopsis
--------

    use PDF::Content::Tag :IllustrationTags, :StructureTags, :ParagraphTags;
    use PDF::Tags;
    use PDF::Tags::Elem;
    use PDF::Class;

    # element creation
    my PDF::Class $pdf .= new;
    my PDF::Tags $tags .= create: :$pdf;
    my PDF::Tags::Elem $doc = $tags.Document;

    my $page = $pdf.add-page;
    my $font = $pdf.core-font: :family<Helvetica>, :weight<bold>;

    $page.graphics: -> $gfx {
        my PDF::Tags::Elem $header = $doc.Header1;
        my PDF::Tags::Mark $mark = $header.mark: $gfx, {
          .say: 'This header is marked',
                :$font,
                :font-size(15),
                :position[50, 120];
          }

        # add a figure with a caption
        my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
        $doc.Figure(:Alt('Incandescent apparatus'))
            .do: $gfx, $img, :position[50, 70];
        $doc.Caption: $gfx, {
            .say("Eureka!", :position[40, 60]),
        }
    }

    $pdf.save-as: "/tmp/tagged.pdf";

    # reading
    $pdf .= open: "/tmp/tagged.pdf";
    $tags .= read: :$pdf;
    $doc = $tags[0]; # root element
    say $doc.name; # Document
    say $doc.kids».name.join(','); # H1,Figure,Caption

Methods
-------

This class inherits from [PDF::Tags::Node::Parent](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node/Parent) and has its method available, (including `cos`, `kids`, `add-kid`, `AT-POS`, `AT-KEY`, `Array`, `Hash`, `find`, `first` and `xml`).

### method attributes

    method attributes() returns Hash
    my %atts = $elem.attributes;

Returns Attributes as a Hash. Attributes may be of various types. For example a `BBox` attribute is generally an array of four numeric values.

### method set-attribute

    method setattribute(Str $name, Any:D $value) returns Any:D;
    $elem.set-attribute('BBox', [0, 0, 200, 50]);

Set a single attribute by name and value.

### method ActualText

    method ActualText() returns Str

Return predefined actual text for the structural node and any children.

Note that ActualText is an optional field in the structure tree. The `text()` method (below) is recommended for generalised text extraction.

### method text

    method text() returns Str

Return the text for the node and its children. Uses `ActualText()` if present in the current node or its ancestors. Otherwise this is computed as concatenated child text elements.

### method Alt

    method Alt() returns Str

Return an alternate description for the structural element and its children in human readable form.

### method do

    method do(
         PDF::Content $gfx, PDF::XObject $image?, *%o
    ) returns Array
    my @rect[4] = $elem.do($page.gfx, $image);

Place an XObject Image or Form as a structural item.

If the object is a Form that contains marked content, its structure is appended to the element. Any other form or image is referenced (see below).

The image argument can be omitted, if the element sub-tree contains an xobject image:

    my PDF::XObject::Form $form = $page.xobject-form: :BBox[0, 0, 200, 50];
    my PDF::Tags::Elem $form-elem = $doc.Form;
    $form.text: {
        my $font-size = 12;
        .text-position = [10, 38];
        $form-elem.Header2: $_, {
            .say: "Tagged XObject header", :font($header-font), :$font-size
        };
        $form-elem.Paragraph: $_, {
            .say: "Some sample tagged text", :font($body-font), :$font-size};
        }

    $form-elem.do($page.gfx, :position[150, 70]);

This is the recommended way of composing an XObject Form with marked content. It will ensure the logical structure is accurately captured, including any nested tags and object references to images, or annotations.

### method reference

    method reference(
        PDF::Content $gfx, PDF::Class::StructItem $Obj
    ) returns PDF::Tags::Elem

Create and place a reference to an XObject (type [PDF::XObject](https://pdf-raku.github.io/PDF-Class-raku)) , Annotation (type [PDF::Annot](https://pdf-raku.github.io/PDF-Class-raku)), or Form (type [PDF::Form](https://pdf-raku.github.io/PDF-Class-raku));

