class PDF::Tags::Node {

    use PDF::COS;
    use PDF::OBJR; # object reference
    use PDF::MCR;  # marked content reference
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::Content::Tag;
    use PDF::Content::Graphics;
    use PDF::Tags::Node::Root;

    my subset TagName of Str is export(:TagName)
        where { !.defined || $_ ~~ /^<ident>$/ }

    has $.cos is required;
    has PDF::Tags::Node::Root $.root is required;
    method set-cos($!cos) {}
    has PDF::Page $.Pg is rw; # current page scope

    proto sub node-class($) is export(:node-class) {*}
    multi sub node-class(PDF::StructTreeRoot) { require ::('PDF::Tags') }
    multi sub node-class(PDF::StructElem)     { require ::('PDF::Tags::Elem') }
    multi sub node-class(PDF::OBJR)           { require ::('PDF::Tags::ObjRef') }
    multi sub node-class(PDF::MCR)            { require ::('PDF::Tags::Mark') }
    multi sub node-class(UInt)                { require ::('PDF::Tags::Mark') }
    multi sub node-class(PDF::Content::Tag)   { require ::('PDF::Tags::Mark') }
    multi sub node-class(Str)                 { require ::('PDF::Tags::Text') }

    proto sub build-node($, |c) is export(:build-node) {*}
    multi sub build-node(PDF::MCR $item, PDF::Page :$Pg, |c) {
        my PDF::Content::Graphics $Stm = $_ with $item.Stm;
        my UInt:D $cos = $item.MCID;
        node-class(PDF::MCR).new(:$cos, :Pg($item.Pg // $Pg), :$Stm, |c);
    }
    multi sub build-node(PDF::OBJR $cos, PDF::Page:D :$Pg = $cos.Pg, |c) {
        node-class(PDF::OBJR).new( :$cos, :$Pg, |c)
    }
    multi sub build-node($_, |c) {
        node-class($_).new: :cos($_), |c;
    }
    
    method xml(|c) { (require ::('PDF::Tags::XML-Writer')).new(|c).Str(self) }
    method text { '' }
}
