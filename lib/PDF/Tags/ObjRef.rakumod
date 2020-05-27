use PDF::Tags::Node :&build-node;

#| Tagged object reference
class PDF::Tags::ObjRef
    is PDF::Tags::Node {
    use PDF::OBJR;
    use PDF::StructElem;
    use PDF::Tags::Node::Parent;
    use PDF::Class::StructItem;

    submethod TWEAK {
        self.Pg = $_ with self.cos.Pg;
    }
    has PDF::Tags::Node::Parent $.parent is rw;
    has PDF::Tags::Node::Parent $!struct-parent;
    method struct-parent {
        $!struct-parent //= do with $.cos.object.struct-parent {
            build-node($.root.parent-tree[$_+0], :$.Pg, :parent($.root));
        }
    }
    method cos(--> PDF::OBJR) { callsame() }

    method name { '#ref' }
    method value(--> PDF::Class::StructItem) { $.cos.object }
}

=begin pod

=head2 Synopsis

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
      my PDF::Tags::Elem $figure = $doc.add-kid(Figure);
      my PDF::XObject::Image $img .= open: "t/images/lightbulb.gif";
      $figure.do: $gfx, $img, :position[50, 70];
      my PDF::Tags::ObjRef $ref = $figure.kids[0];
      say $ref.value === $img; # True
  }

=head2 Description

A PDF::Tags::ObjRef contains a reference to an object of type
PDF::Annot (annotation), PDF::Form (Acrobat form), or PDF::XObject (image). These all perform the PDF::Class::StructItem role.

These appear as leaf nodes in a tagged PDF's usually along-side PDF::Tags::Mark objects to indicate the objects logical positioning in document reading-order.

Note that xobject forms (type PDF::XObject::Form) can be referenced in two
different ways:

=item as multiple PDF::Tag::Mark references to marked content within the form's stream.
=item as a single PDF::Tag::ObjRef reference

Depending on whether or not the form contains significant sub-structure.

=head2 Methods
=head3 method value

    method value returns PDF::Class::StructItem

The referenced COS object; of type PDF::XObject, PDF::Annot or PDF::Form (PDF::Class::StructItem role).

=end pod
