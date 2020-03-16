class PDF::Tags::Item {

    use PDF::COS;
    use PDF::OBJR; # object reference
    use PDF::MCR;  # marked content reference
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::Content::Tag;
    use PDF::Content::Graphics;
    use PDF::Tags::Root;

    has PDF::Tags::Root $.root is required;
    has $.cos is required;
    method set-cos($!cos) {}
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
        my UInt:D $cos = $item.MCID;
        item-class(PDF::MCR).new(:$cos, :Pg($item.Pg // $Pg), :$Stm, |c);
    }
    multi sub build-item(PDF::OBJR $cos, PDF::Page:D :$Pg = $cos.Pg, |c) {
        item-class(PDF::OBJR).new( :$cos, :$Pg, |c)
    }
    multi sub build-item($_, |c) {
        item-class($_).new: :cos($_), |c;
    }
    
    method xml(|c) { (require ::('PDF::Tags::XML-Writer')).new(|c).Str(self) }
    method text { '' }
}
