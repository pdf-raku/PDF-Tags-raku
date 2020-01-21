class PDF::DOM::Item {
    use PDF::DOM;
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::OBJR;

    has PDF::DOM $.dom handles<root> is required;
    has $.item is required;
    method set-item($!item) {}
    has PDF::Page $.Pg is rw; # current page scope

    proto sub item-class($) is export(:item-class) {*}
    multi sub item-class(PDF::StructTreeRoot) { require ::('PDF::DOM::Root') }
    multi sub item-class(PDF::StructElem)     { require ::('PDF::DOM::Elem') }
    multi sub item-class(PDF::OBJR)           { require ::('PDF::DOM::Link') }
    multi sub item-class(UInt)                { require ::('PDF::DOM::Tag') }
    multi sub item-class(Str)                 { require ::('PDF::DOM::Text') }
}