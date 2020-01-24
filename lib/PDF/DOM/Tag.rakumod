use PDF::DOM::Node;
class PDF::DOM::Tag is PDF::DOM::Node {
    use PDF::Page;
    use PDF::COS::TextString;
    use PDF::Content::Tag;
    use PDF::Content::Tag::Marked;
    has PDF::DOM::Node $.parent;
    has %!attributes;
    has Bool $!atts-built;
    has Str $!actual-text;

    multi submethod TWEAK(PDF::Content::Tag::Marked:D :$item!) {
        self.set-item($item);
    }
    multi submethod TWEAK(UInt:D :$item!) {
        with self.Pg -> PDF::Page $Pg {
            with self.dom.graphics-tags($Pg){$item} {
                self.set-item($_);
            }
            else {
                die "unable to resolve MCID: $item";
            }
        }
        else {
            die "no current marked-content page";
        }
    }
    method item(--> PDF::Content::Tag) { callsame() }
    method tag { $.item.name }
    method attributes handles<AT-KEY> {
        $!atts-built ||= do {
            %!attributes = $.item.attributes;
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
}
