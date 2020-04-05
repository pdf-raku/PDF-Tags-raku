class PDF::Tags::XPath {

    use PDF::Tags;
    use PDF::Tags::Node;
    use PDF::Tags::XPath::Grammar;
    use PDF::Tags::XPath::Actions;
    use Method::Also;

    has PDF::Tags::Node $.node;

    method compile(Str:D $expr --> Code) {
        my PDF::Tags::XPath::Actions $actions .= new;
        fail "can't handle xpath: $expr"
           unless PDF::Tags::XPath::Grammar.parse($expr, :$actions);
        $/.ast;
    }

    multi method find(Any $expr, PDF::Tags:D $dom) {
        $!node = $dom.root;
        self.find($expr);
    }

    multi method find(Any $expr, PDF::Tags::Node:D $!node) {
        self.find($expr);
    }

    multi method find(Str:D $xpath) is also<AT-KEY> {
        my PDF::Tags::XPath::Actions::Expression $expr := self.compile($xpath);
        self.find($expr);
    }

    my subset Listy where List|Seq;
    multi method find(&expr --> Listy) {
        &expr($!node);
    }

}

=begin pod
=end pod
