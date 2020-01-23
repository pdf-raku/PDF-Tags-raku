use PDF::DOM::Node;
class PDF::DOM::Tag is PDF::DOM::Node {
    use PDF::Page;
    use PDF::Content::Tag;
    has PDF::DOM::Node $.parent;

    submethod TWEAK(UInt :$item!) {
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
    method item(--> PDF::Content::Tag) handles<attributes> { callsame() }
    method tag { $.item.name }
}
