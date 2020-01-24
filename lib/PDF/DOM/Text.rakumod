use PDF::DOM::Node;
class PDF::DOM::Text is PDF::DOM::Item {
    use PDF::Page;
    use PDF::Content::Tag;
    use Method::Also;

    has PDF::DOM::Node $.parent;

    submethod TWEAK(Str :$item!) {
        self.set-item($item);
    }
    method item(--> Str) is also<Str gist text> { callsame() }
    method tag { '#text' }
}
