#| Derived Text node
unit class PDF::Tags::Text;

use PDF::Tags::Node;
also is PDF::Tags::Node;

use PDF::Tags::Node::Parent;
use Method::Also;

=head2 Description
=para Objects of this class hold derived text.
=head2 Attributes and Methods

submethod TWEAK(Str:D :$cos!) {
    self.set-cos($cos);
}

#| The parent node
has PDF::Tags::Node::Parent $.parent is rw;
=para of type PDF::Tags::Elem, or PDF::Tags::Mark

#| Node name (always '#text')
method name { '#text' }

#| Text content
method Str(--> Str) is also<gist text value ActualText> { $.cos() }


