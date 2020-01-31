use PDF::Tagged::Node;
class PDF::Tagged::Text is PDF::Tagged::Item {
    use PDF::Page;
    use PDF::Content::Tag;
    use Method::Also;

    has PDF::Tagged::Node $.parent;

    submethod TWEAK(Str :$value!) {
        self.set-value($value);
    }
    method value(--> Str) is also<Str gist text> { callsame() }
    method tag { '#text' }
}
