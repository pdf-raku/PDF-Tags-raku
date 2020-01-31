class PDF::Tagged::XPath::Context {

    use PDF::Tagged::Node;
    use PDF::Tagged::XPath::Grammar;
    use PDF::Tagged::XPath::Actions;

    has PDF::Tagged::Node $.node;

    method compile(Str:D $expr --> Code) {
        my PDF::Tagged::XPath::Actions $actions .= new;
        fail "can't handle xpath: $expr"
           unless PDF::Tagged::XPath::Grammar.parse($expr, :$actions);
        $/.ast;
    }

    multi method find(Any $expr, PDF::Tagged:D $dom) {
        $!node = $dom.root;
        self.find($expr);
    }

    multi method find(Any $expr, PDF::Tagged::Item:D $!node) {
        self.find($expr);
    }

    multi method find(Str:D $xpath) {
        my PDF::Tagged::XPath::Actions::Expression $expr := self.compile($xpath);
        self.find($expr);
    }

    multi method find(&expr) {
        &expr($!node);
    }

    method AT-KEY($k, |c) {
        my % = classify *.tag, self.find($k, |c);
    }

}