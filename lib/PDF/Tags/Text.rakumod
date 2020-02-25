use PDF::Tags::Node;
class PDF::Tags::Text is PDF::Tags::Item {
    use PDF::Page;
    use PDF::Content::Tag;
    use Method::Also;

    has PDF::Tags::Node $.parent;

    submethod TWEAK(Str :$value!) {
        self.set-value($value);
    }
    method tag { '#text' }
    method value(--> Str) is also<Str gist text> { callsame() }
}
