use PDF::DOM::Item :&item-class, :&build-item;

class PDF::DOM::Node
    is PDF::DOM::Item {

    has PDF::DOM::Item @.kids;
    has Bool $!loaded;
    has UInt $!elems;
    method elems {
        $!elems //= do with $.item.kids {
            when Hash { 1 }
            default { .elems }
        } // 0;
    }

    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        my Any:D $item = $.item.kids[$i];
        @!kids[$i] //= build-item($item, :parent(self), :$.Pg, :$.dom);
    }
    method Array {
        $!loaded ||= do {
            self.AT-POS($_) for 0 ..^ $.elems;
            True;
        }
        @!kids;
    }
    method kids {
        my class Kids does Iterable does Iterator does Positional {
            has PDF::DOM::Item $.node is required handles<elems AT-POS>;
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
