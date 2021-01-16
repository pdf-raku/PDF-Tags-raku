[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [ObjRef](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/ObjRef)

class PDF::Tags::ObjRef
-----------------------

Tagged object reference

Synopsis
--------

    use PDF::Content::Tag :StructureTags, :IllustrationTags;
    use PDF::Tags;
    use PDF::Tags::Elem;
    use PDF::Tags::ObjRef;

    # PDF::Class
    use PDF::Class;
    use PDF::Page;
    use PDF::XObject::Image;

    my PDF::Class $pdf .= new;
    my PDF::Tags $tags .= create: :$pdf;
    # create the document root
    my PDF::Tags::Elem $doc = $tags.Document;

    my PDF::Page $page = $pdf.add-page;

    $page.graphics: -> $gfx {
        my PDF::Tags::Elem $figure = $doc.Figure: :Alt("Example image");
        my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
        $figure.do: $gfx, $img, :position[50, 70];
        # verify that we have created an object reference to the image
        my PDF::Tags::ObjRef $ref = $figure.kids[0];
        say $ref.value === $img; # True
    }

Description
-----------

A PDF::Tags::ObjRef contains a reference to an object of type [PDF::Annot](https://pdf-raku.github.io/PDF-Class-raku) (annotation), [PDF::Form](https://pdf-raku.github.io/PDF-Class-raku) (Acrobat form), or [PDF::XObject](https://pdf-raku.github.io/PDF-Class-raku) (image). These all perform the PDF::Class::StructItem role.

These appear as leaf nodes in a tagged PDF's usually along-side [PDF::Tags::Mark](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Mark) objects to indicate the objects logical positioning in document reading-order.

Note that xobject forms (type [PDF::XObject::Form](https://pdf-raku.github.io/PDF-Class-raku)) can be referenced in two different ways:

  * as multiple [PDF::Tag::Mark](https://pdf-raku.github.io/PDF-Class-raku) references to marked content within the form's stream.

  * as a single [PDF::Tag::ObjRef](https://pdf-raku.github.io/PDF-Class-raku) reference

Depending on whether or not the form contains significant sub-structure.

Methods
-------

### method value

    method value returns PDF::Class::StructItem

The referenced COS object; of type [PDF::XObject](https://pdf-raku.github.io/PDF-Class-raku), [PDF::Annot](https://pdf-raku.github.io/PDF-Class-raku) or [PDF::Form](https://pdf-raku.github.io/PDF-Class-raku) (PDF::Class::StructItem role).

