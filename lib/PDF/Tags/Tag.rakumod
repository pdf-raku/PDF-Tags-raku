#| Any tagged content in a content stream
unit class PDF::Tags::Tag;

use PDF::Tags::Node::Parent;
also is PDF::Tags::Node::Parent;

use PDF::Content::Tag;

has PDF::Tags::Node::Parent $.parent is rw;
has PDF::Content::Tag $.value is built handles<name mcid elems>;
has %!attributes;
has Bool $!atts-built;

has Str $.actual-text is rw;

multi submethod TWEAK(PDF::Content::Tag:D :cos($!value)!, Str :$!actual-text) {
}

multi submethod TWEAK(UInt:D :cos($)!, Str :$!actual-text where self.isa('PDF::Tags::Mark')) {
}

method set-attribute(Str() $key, $val) {
    $.attributes{$key} = $val;
}

method attributes {
    $!atts-built ||= do {
        %!attributes = $!value.attributes;
        True;
    }
    %!attributes;
}

method set-value($!value) {
    $!atts-built = False;
}

sub sanitize(Str $_) {
    # actual text sometimes have backspaces, etc?
    .subst(
        /<[ \x0..\x8 ]>/,
        '',
        :g
    );
}
method ActualText {
    $.attributes unless $!atts-built;
    $!actual-text //= sanitize PDF::COS::TextString.COERCE: $_
        with %.attributes<ActualText>;
    $!actual-text;
}

method text { $.ActualText // $.kids».text.join }

method AT-POS(UInt $i) {
    fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
    self.kids-raw[$i] //= self.build-kid($!value.kids[$i]);
}
