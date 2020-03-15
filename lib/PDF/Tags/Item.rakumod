class PDF::Tags::Item {

    use PDF::OBJR; # object reference
    use PDF::MCR;  # marked content reference
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::Content::Tag;
    use PDF::Content::Graphics;
    use PDF::Tags::Root;

    has PDF::Tags::Root $.root is required;
    has $.value is required;
    method set-value($!value) {}
    has PDF::Page $.Pg is rw; # current page scope

    proto sub item-class($) is export(:item-class) {*}
    multi sub item-class(PDF::StructTreeRoot)     { require ::('PDF::Tags::Root') }
    multi sub item-class(PDF::StructElem)         { require ::('PDF::Tags::Elem') }
    multi sub item-class(PDF::OBJR)               { require ::('PDF::Tags::ObjRef') }
    multi sub item-class(PDF::MCR)                { require ::('PDF::Tags::Mark') }
    multi sub item-class(UInt)                    { require ::('PDF::Tags::Mark') }
    multi sub item-class(PDF::Content::Tag) { require ::('PDF::Tags::Mark') }
    multi sub item-class(Str)                     { require ::('PDF::Tags::Text') }

    proto sub build-item($, |c) is export(:build-item) {*}
    multi sub build-item(PDF::MCR $item, PDF::Page :$Pg, |c) {
        my PDF::Content::Graphics $Stm = $_ with $item.Stm;
        my UInt:D $value = $item.MCID;
        item-class(PDF::MCR).new(:$value, :Pg($item.Pg // $Pg), :$Stm, |c);
    }
    multi sub build-item(PDF::OBJR $value, PDF::Page:D :$Pg = $value.Pg, |c) {
        item-class(PDF::OBJR).new( :$value, :$Pg, |c)
    }
    multi sub build-item($value, |c) {
        item-class($value).new: :$value, |c;
    }
    
    method xml(|c) { (require ::('PDF::Tags::XML-Writer')).new(|c).Str(self) }
    method text { '' }
}
