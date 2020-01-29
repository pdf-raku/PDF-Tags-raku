class PDF::DOM::Item {
    use PDF::DOM;
    use PDF::OBJR; # object reference
    use PDF::MCR;  # marked content reference
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::Content::Tag::Marked;

    has PDF::DOM $.dom handles<root> is required;
    has $.value is required;
    method set-value($!value) {}
    has PDF::Page $.Pg is rw; # current page scope

    proto sub item-class($) is export(:item-class) {*}
    multi sub item-class(PDF::StructTreeRoot) { require ::('PDF::DOM::Root') }
    multi sub item-class(PDF::StructElem)     { require ::('PDF::DOM::Elem') }
    multi sub item-class(PDF::OBJR)           { require ::('PDF::DOM::ObjRef') }
    multi sub item-class(PDF::MCR)            { require ::('PDF::DOM::Tag') }
    multi sub item-class(UInt)                { require ::('PDF::DOM::Tag') }
    multi sub item-class(PDF::Content::Tag::Marked) { require ::('PDF::DOM::Tag') }
    multi sub item-class(Str)                 { require ::('PDF::DOM::Text') }

    proto sub build-item($, |c) is export(:build-item) {*}
    multi sub build-item(PDF::MCR $item, PDF::Page :$Pg, |c) {
        build-item($item.MCID, :Pg($item.Pg // $Pg), |c);
    }
    multi sub build-item($value, |c) {
        item-class($value).new: :$value, |c;
    }
    
    method xml(|c) { (require ::('PDF::DOM::XML')).new(|c).Str(self) }
    method text { '' }
}