use PDF::DOM::Node;
use PDF::StructElem;
class PDF::DOM::Elem is PDF::DOM::Node {
    method item(--> PDF::StructElem) handles<tag> { callsame() }
    has $.parent is required;
    has Hash $!attributes;
    method attributes handles<AT-KEY> {
        $!attributes //= do {
            ...
        }
    }
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
}
