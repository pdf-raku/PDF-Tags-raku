use PDF::Tags::Node;
class PDF::Tags::Mark is PDF::Tags::Node {

    use PDF::Page;
    use PDF::COS;
    use PDF::COS::TextString;
    use PDF::Content::Tag;
    use PDF::Content::Tag;
    use PDF::Content::Graphics;
    use PDF::MCR;

    has PDF::Tags::Node $.parent is rw;
    has %!attributes;
    has Bool $!atts-built;
    has Str $!actual-text;
    has PDF::Content::Graphics $.Stm;
    has PDF::Content::Tag $.mark is built handles<name mcid elems>;

    method set-cos($!mark) {
        my PDF::MCR $mcr;
        with $.mcid -> $MCID {
            # only linked into the struct-tree if it has an MCID attribute
            my PDF::Page $Pg = $!mark.owner ~~ PDF::Page ?? $!mark.owner !! $.Pg;

            $mcr = PDF::COS.coerce: %(
                :Type( :name<MCR> ),
                :$MCID,
                :$Pg,
            );
            $mcr<Stm> = $_ with $!Stm;
        }
        callwith($mcr);
    }

    multi submethod TWEAK(PDF::Content::Tag:D :cos($_)!) {
        self.set-cos($_);
    }
    multi submethod TWEAK(UInt:D :$cos!) {
        with self.Stm // self.Pg -> PDF::Content::Graphics $_ {
            with self.root.graphics-tags($_){$cos} {
                self.set-cos($_);
            }
            else {
                die "unable to resolve MCID: $cos";
            }
        }
        else {
            die "no current marked-content page";
        }
    }
    method cos(--> PDF::MCR) { callsame() }
    method attributes handles<AT-KEY> {
        $!atts-built ||= do {
            %!attributes = $!mark.attributes;
            do with %!attributes<ActualText>:delete -> $cos {
                $!actual-text = PDF::COS::TextString.new(:$cos);
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
    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        self.kids-raw[$i] //= self.build-kid($!mark.kids[$i]);
    }
}

=begin pod
=end pod
