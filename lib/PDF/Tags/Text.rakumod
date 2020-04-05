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
    method cos(--> Str) is also<Str gist text> { callsame() }
}

=begin pod
=end pod
