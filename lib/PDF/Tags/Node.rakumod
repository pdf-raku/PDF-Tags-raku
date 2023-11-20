#| Abstract Node
class PDF::Tags::Node {

    use PDF::COS;
    use PDF::OBJR; # object reference
    use PDF::MCR;  # marked content reference
    use PDF::Page;
    use PDF::StructTreeRoot;
    use PDF::StructElem;
    use PDF::Content::Tag;
    use PDF::Content::Canvas;
    use PDF::Tags::Node::Root;
    use Method::Also;

    my subset TagName of Str is export(:TagName)
        where Str:U | /^<ident>$/;

    has PDF::Tags::Node::Root $.root is required handles<role-map artifacts>;
    has PDF::Page $.Pg; # current page scope
    has $.cos is required;
    method set-cos($!cos) { }
    method Pg is rw {
        Proxy.new(
            FETCH => {$!Pg},
            STORE => -> $, $!Pg {
                $!cos.Pg = $!Pg if $!cos ~~ PDF::OBJR|PDF::MCR|PDF::StructElem;
            }
        );
    }

    proto sub node-class($) is export(:node-class) {*}
    multi sub node-class(PDF::StructTreeRoot) { require ::('PDF::Tags') }
    multi sub node-class(PDF::StructElem)     { require ::('PDF::Tags::Elem') }
    multi sub node-class(PDF::OBJR)           { require ::('PDF::Tags::ObjRef') }
    multi sub node-class(PDF::MCR)            { require ::('PDF::Tags::Mark') }
    multi sub node-class(UInt)                { require ::('PDF::Tags::Mark') }
    multi sub node-class(PDF::Content::Tag)   { require ::('PDF::Tags::Mark') }
    multi sub node-class(Str)                 { require ::('PDF::Tags::Text') }
    multi sub node-class(Pair)                { require ::('PDF::Tags::Attr') }

    proto sub build-node($, |c --> PDF::Tags::Node) is export(:build-node) {*}
    multi sub build-node(PDF::MCR $ref, PDF::Page :$Pg is copy, |c) {
        my PDF::Content::Canvas $Stm = $_ with $ref.Stm;
        my UInt:D $cos = $ref.MCID;
        $Pg = $_ with $ref.Pg;
        node-class($ref).new(:$cos, :$Pg, :$Stm, |c);
    }
    multi sub build-node(PDF::OBJR $cos, PDF::Page:D :$Pg = $cos.Pg, |c) {
        node-class($cos).new( :$cos, :$Pg, |c)
    }
    multi sub build-node($cos, |c) {
        node-class($cos).new: :$cos, |c;
    }
    
    method xml(|c) is also<Str gist> { (require ::('PDF::Tags::XML-Writer')).new(|c).Str(self) ~ "\n" }
    method text { '' }

    method xpath-context(PDF::Tags::Node:D $node:) handles<find first> {
        (require ::('PDF::Tags::XPath')).new: :$node;
    }

    multi method ACCEPTS(PDF::Tags::Node:D: Str $xpath) {
        ? self.find($xpath);
    }
    multi method ACCEPTS(PDF::Tags::Node:D: Code $xpath) {
        ? self.find($xpath);
    }
}

=begin pod

=head2 Methods

=head3 method cos

Returns the underlying L<PDF::Class> or L<PDF::Content> object. The L<PDF::Tags::Node> subclass and L<PDF::COS> type are mapped as follows:

=begin table
PDF::Tags::Node object | PDF::Class object  |Base class | Notes
=================================================
PDF::Tags | PDF::StructTreeRoot | PDF::Tags::Node::Parent | PDF structure tree root
PDF::Tags::Elem | PDF::StructElem | PDF::Tags::Node::Parent | Intermediate structure element node
PDF::Tags::Mark | PDF::MCR | PDF::Tags::Parent | Leaf marked content reference
PDF::Tags::ObjRef | PDF::OBJR | PDF::Tags::Node | Leaf object reference
PDF::Tags::Text | N/A | PDF::Tags::Node | Looking to eliminate this class?
=end table

=head3 method root

    method root() returns PDF::Tags

Link to the structure tree root.

=head3 method find (alias AT-KEY)

    method find is also<AT-KEY> returns Seq
    say $tags.find('Document/L[1]/@O')[0].name'
    say $tags<Document/L[1]/@O>[0].name'

This method evaluates an XPath like expression (see PDF::Tags::XPath) and returns a
sequence of matching nodes.

With the exception that `$node.AT-KEY($node-name)` routes to `$node.Hash{$node-name}`, rather than
using the XPath engine.

=head3 method first

    method first($expr) returns PDF::Tags::Node
    say $tags.first('Document/L[1]/@O').name;

Like find, except the first matching node is returned.

=head3 method xml

    method xml(*%opts) returns Str

Serialize a node and any descendants as XML.

Calling `$node.xml(|c)`, is equivalent to: `PDF::Tags::XML-Writer.new(|c).Str($node)`

=end pod
