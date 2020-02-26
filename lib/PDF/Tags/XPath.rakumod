class PDF::Tags::XPath {

    use PDF::Tags::Node;
    use PDF::Tags::XPath::Grammar;
    use PDF::Tags::XPath::Actions;

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

    multi method find(Any $expr, PDF::Tags::Item:D $!node) {
        self.find($expr);
    }

    multi method find(Str:D $xpath) {
        my PDF::Tags::XPath::Actions::Expression $expr := self.compile($xpath);
        self.find($expr);
    }

    multi method find(&expr) {
        &expr($!node);
    }

    method AT-KEY($k, |c) {
        my % = classify *.tag, self.find($k, |c);
    }

}

=begin pod
=end pod
