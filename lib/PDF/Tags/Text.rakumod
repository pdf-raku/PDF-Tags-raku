use PDF::Tags::Node;
class PDF::Tags::Text
    is PDF::Tags::Node {
    use PDF::Tags::Node::Parent;
    use Method::Also;

    has PDF::Tags::Node::Parent $.parent is rw;

    submethod TWEAK(Str :$cos!) {
        self.set-cos($cos);
    }
    method name { '#text' }
    method cos(--> Str) is also<Str gist text value> { callsame() }
}

=begin pod
=head1 NAME

PDF::Tags::Text - Derived Text node

=head1 DESCRIPTION

Objects of this class hold derived text.

=head1 METHODS

=begin item
Str / gist / text

The text content
=end item

=begin item
parent

The parent node; of type PDF::Tags::Elem, or PDF::Tags::Mark
=end item

=end pod
