use PDF::DOM::Node;
class PDF::DOM::Tag is PDF::DOM::Item {
    use PDF::Page;
    use PDF::Content::Tag;
    has PDF::DOM::Node $.parent;

    submethod TWEAK(Str :$item!) {
        self.set-item($item);
    }
    method item(--> Str) { callsame() }
    method tag { '#text' }
}
