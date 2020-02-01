use PDF::Tags::Node;
class PDF::Tags::Tag is PDF::Tags::Node {
    use PDF::Page;
    use PDF::COS::TextString;
    use PDF::Content::Tag;
    use PDF::Content::Tag::Marked;
    has PDF::Tags::Node $.parent;
    has %!attributes;
    has Bool $!atts-built;
    has Str $!actual-text;

    multi submethod TWEAK(PDF::Content::Tag::Marked:D :$value!) {
        self.set-value($value);
    }
    multi submethod TWEAK(UInt:D :$value!) {
        with self.Pg -> PDF::Page $Pg {
            with self.dom.graphics-tags($Pg){$value} {
                self.set-value($_);
            }
            else {
                die "unable to resolve MCID: $value";
            }
        }
        else {
            die "no current marked-content page";
        }
    }
    method value(--> PDF::Content::Tag) { callsame() }
    method tag { $.value.name }
    method attributes handles<AT-KEY> {
        $!atts-built ||= do {
            %!attributes = $.value.attributes;
            do with %!attributes<ActualText>:delete -> $value {
                $!actual-text = PDF::COS::TextString.new(:$value);
            }
            True;
        }
        %!attributes;
    }
    method actual-text {
        $.attributes unless $!atts-built;
        $!actual-text;
    }
    method text { $.actual-text // $.kids.map(*.text).join }
}
