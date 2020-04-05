use PDF::Tags::Node;
class PDF::Tags::Attr
    is PDF::Tags::Node {
    use PDF::Tags::Node::Parent;
    use Method::Also;

    has PDF::Tags::Node::Parent $.parent is rw;

    submethod TWEAK(Pair :$cos!) {
        self.set-cos($cos);
    }
    method name { $.cos.key }
    method text is also<Str> { $.cos.value }
    method gist { [~] '@', $.cos.key, '=', $.cos.value }
    method cos(--> Pair) is also<kv> { callsame() }
}

=begin pod
=end pod
