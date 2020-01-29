class PDF::DOM::XPath::Context {

    use PDF::DOM::Node;
    use PDF::DOM::XPath::Grammar;
    use PDF::DOM::XPath::Actions;

    has PDF::DOM::Node $.node;

    method compile(Str:D $expr --> Code) {
        my PDF::DOM::XPath::Actions $actions .= new;
        fail "can't handle xpath: $expr"
           unless PDF::DOM::XPath::Grammar.parse($expr, :$actions);
        $/.ast;
    }

    multi method find(Any $expr, PDF::DOM:D $dom) {
        $!node = $dom.root;
        self.find($expr);
    }

    multi method find(Any $expr, PDF::DOM::Item:D $!node) {
        self.find($expr);
    }

    multi method find(Str:D $xpath) {
        my PDF::DOM::XPath::Actions::Expression $expr := self.compile($xpath);
        self.find($expr);
    }

    multi method find(&expr) {
        &expr($!node);
    }

    method AT-KEY($k, |c) {
        my % = classify *.tag, self.find($k, |c);
    }

}