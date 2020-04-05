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
    multi sub node-class(Pair)                { require ::('PDF::Tags::Attr') }

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

=begin pod
=head1 NAME

PDF::Tags::Node - Abstract node class

=head1 DESCRIPTION

Abstract node ancestor class.

=head1 METHODS

=begin item
cos

Returns the underlying PDF::Class or PDF::Content object. The PDF::Tags::Node subclass and PDF::COS type are interdependant:

=begin table
PDF::Tags:Node object | PDF::Class object |Base class | Notes
=================================================
PDF::Tags | PDF::StructTreeRoot | PDF::Tags::Node::Parent | PDF structure tree root
PDF::Tags::Elem | PDF::StructElem | PDF::Tags::Node::Parent | Intermediate structure element node
PDF::Tags::Mark | PDF::MCR | PDF::Tags::Parent | Leaf marked content reference
PDF::Tags::ObjRef | PDF::OBJR | PDF::Tags::Node | Leaf object reference
PDF::Tags::Text | N/A | PDF::Tags::Node | Looking to eliminate this class?
=end table

=end item

=begin item
root

Link to the structure tree root.
=end item

=begin item
xml

Serialize a node and any descendants as XML.

Calling `$node.xml(|c)`, is equivalant to: `PDF::Tags::XML-Writer.new(|c).Str`

=end item

=end pod
