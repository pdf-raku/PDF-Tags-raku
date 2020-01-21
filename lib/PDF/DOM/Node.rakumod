class PDF::DOM::Node {
    use PDF::DOM;
    use PDF::StructTreeRoot;
    use PDF::StructElem;

    has PDF::DOM $.dom handles<root> is required;
    has $.item is required;
    has PDF::DOM::Node @.kids;
    has Bool $!loaded;
    has UInt $.elems is built;
    has PDF::Page $.Pg is rw; # current page scope
    submethod TWEAK {
        $!elems = do with $!item.K {
            when Hash { 1 }
            default { .elems }
        } // 0;
    }
    multi sub node-class(PDF::StructTreeRoot) { require ::('PDF::DOM::Root') }
    multi sub node-class(PDF::StructElem)     { require ::('PDF::DOM::Elem') }

    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $!elems: $i" unless 0 <= $i < $!elems;
        my Any:D $item = $!item<K>[$i];
        @!kids[$i] //= node-class($item).new: :parent(self), :$item, :$!Pg, :$!dom;
    }
    method Array {
        $!loaded ||= do {
            self.AT-POS($_) for 0 ..^ $!elems;
        }
        @!kids;
    }
    method kids {
        my class Kids does Iterable does Iterator does Positional {
            has PDF::DOM::Node $.node is required handles<elems AT-POS>;
            has int $!idx = 0;
            method iterator { $!idx = 0; self}
            method pull-one {
                $!idx < $!node.elems ?? $!node.AT-POS($!idx++) !! IterationEnd;
            }
            method Array handles<List list values map grep> { $!node.Array }
        }
        Kids.new: :node(self);
    }

    method find(Str $xpath) {
        (require ::('PDF::DOM::XPath')).new(:$xpath).find(:ref(self))
    }
    method first(Str $xpath) {
        self.find($xpath)[0] // PDF::DOM::Node
    }
}
