use PDF::Tags::Item :&build-item;

class PDF::Tags::ObjRef is PDF::Tags::Item {
    use PDF::OBJR;
    use PDF::StructElem;
    use PDF::Tags::Node;
    submethod TWEAK {
        self.Pg = $_ with self.cos.Pg;
    }
    has PDF::Tags::Node $.parent is rw;
    has PDF::Tags::Item $!struct-parent;
    method struct-parent {
        $!struct-parent //= do with $.cos.object.struct-parent {
            build-item($.root.parent-tree[$_+0], :$.Pg, :parent($.root));
        }
        $!struct-parent;
    }
    method cos(--> PDF::OBJR) handles<object> { callsame() }

    method name { '#ref' }
}

=begin pod
=head1 NAME

PDF::Tags::ObjRef - Tagged object reference

=head1 SYNOPSIS

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
  my PDF::Tags::Elem $doc = $tags.add-kid(Document);

  my PDF::Page $page = $pdf.add-page;

  $page.graphics: -> $gfx {

      my $figure = $doc.add-kid(Figure);
      my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
      $figure.do: $gfx, $img, :position[50, 70];
      my PDF::Tags::ObjRef $ref = $figure.kids[0];
      say $ref.object === $img; # True
  }

=head1 DESCRIPTION

A PDF::Tags::ObjRef contains a reference to an object of type
PDF::Annot (annotation), PDF::Form (Acrobat form), or PDF::XObject (image).

These appear as leaf nodes in a tagged PDF's usually along-side PDF::Tags::Mark objects to indicate the objects logical positioning in document reading-order.

Note that xobject forms (type PDF::XObject::Form) can be referenced in two
different ways:

    =item as a single PDF::Tag::ObjRef reference
    =item as multiple PDF::Tag::Mark references to marked content within the form's stream.

Depending on whether the form can be treated as an atomic image, or if contains significant sub-structure.

=end pod
