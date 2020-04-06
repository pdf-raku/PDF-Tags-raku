use PDF::Tags::Node :&node-class, :&build-node, :TagName;

class PDF::Tags::Node::Parent
    is PDF::Tags::Node {

    use Method::Also;
    use PDF::COS;
    use PDF::StructElem;

    has PDF::Tags::Node @.kids;
    method kids-raw { @!kids }
    has Hash $!store;
    has Bool $!reified;
    has UInt $!elems;

    method elems is also<Numeric> {
        $!elems //= do with $.cos.kids {
            when Hash { 1 }
            default { .elems }
        } // 0;
    }

    method build-kid($cos, :$Pg = $.Pg, |c) {
        build-node($cos, :parent(self), :$Pg, :$.root, |c);
    }

    method !adopt-node($node) {
        # checks
        die "unable to add a node to itself"
            if $node === self || $node.cos === self.cos;

        with $node.parent {
            die "node already parented"
                unless $_ === self;
        }

        # reparent cos node
        given self.cos.kids //= [] {
            $_ = [$_] if $_ ~~ Hash;
            $node.cos.P = self.cos
                if $node.cos ~~ PDF::StructElem;
            .push($node.cos);
        }

        # reparent dom node
        $node.parent = self;
        @!kids.push: $node;

        # update caches
        $!elems = Nil;
        self.AT_POS($.elems-1) if $!reified;
        .{$node.name}.push: $node with $!store;

        $node;
    }
    multi method add-kid(PDF::Tags::Node:D $node) {
        self!adopt-node($node);
    }
    multi method add-kid(Str:D $name, |c) {
        my $P := self.cos;
        my PDF::StructElem $cos = PDF::COS.coerce: %(
            :Type( :name<StructElem> ),
            :S( :$name ),
            :$P,
        );
        self.add-kid($cos, |c)
    }
    multi method add-kid($cos, |c ) is default {
        my PDF::Tags::Node $kid := self.build-kid($cos, |c);
        self!adopt-node($kid);
    }
    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        @!kids[$i] //= self.build-kid($.cos.kids[$i]);
    }
    method Array {
        $!reified ||= do {
            self.AT-POS($_) for 0 ..^ $.elems;
            True;
        }
        @!kids;
    }
    method Hash handles <keys pairs> {
        $!store //= do {
            my %h;
            %h{.name}.push: $_ for self.Array;
            if self.can('attributes') {
                %h{'@' ~ .key} = .value
                   for self.attributes.pairs;
            }
            %h;
        }
    }
    method set-attribute(Str $key, $val) {
        fail "attributes not applicable to objects of type {self.WHAT.raku}"
            unless self.can('attributes');
        .{$key} = $val with $!store;
    }
    multi method AT-KEY(TagName:D $name) {
        # tag name
        @(self.Hash{$name} // []);
    }
    multi method AT-KEY(Str:D $xpath) is default {
        $.xpath-context.AT-KEY($xpath);
    }
    method kids {
        my class Kids does Iterable does Iterator does Positional {
            has PDF::Tags::Node $.node is required handles<elems AT-POS Numeric>;
            has int $!idx = 0;
            method iterator { $!idx = 0; self}
            method pull-one {
                $!idx < $!node.elems ?? $!node.AT-POS($!idx++) !! IterationEnd;
            }
            method Array handles<List list values map grep> { $!node.Array }
        }
        Kids.new: :node(self);
    }

    method xpath-context {
        (require ::('PDF::Tags::XPath')).new: :node(self);
    }
    method find($expr) { $.xpath-context.find($expr) }

    method first($expr) {
        self.find($expr)[0] // PDF::Tags::Node
    }

    multi method ACCEPTS(PDF::Tags::Node::Parent:D: Str $xpath) {
        ? self.find($xpath);
    }
    multi method ACCEPTS(PDF::Tags::Node::Parent:D: Code $xpath) {
        ? self.find($xpath);
    }
}

=begin pod
=head1 NAME

PDF::Tags::Node::Parent - Abstract non-leaf node

=head1 DESCRIPTION

This is a base class for nodes that may contain child elements (objects of type:
PDF::Tags, PDF::Tags::Elem and PDF::Tags::Mark).

=head1 METHODS

=begin item
AT-POS

   my $third-child = $node[2];

`node[$n]` is equivalent to `node.kids[$n]`.
=end item

=begin item
Array

Returns all child nodes as an array.
=end item

=begin item
kids

Returns an iterator for the child elements:

    for $node.kids -> PDF::Tags::Node $kid { ... }
    my @kids = $node.kids;  # consume all at once

Unlike the `Array` and `Hash` methods `kids` does not cache child elements
and may be ore efficient for one-off traversal of larger DOMs.    
=end item

=begin item
find / AT-KEY

    say $tags.find('Document/L[1]/@O')[0].name'
    say $tags<Document/L[1]/@O>[0].name'

This method evaluates an XPath like expression (see PDF::Tags::XPath) and returns a
list of matching nodes.

With the exception that `$node.AT-KEY($node-name)` routes to `$node.Hash{$node-name}`, rather than
using the XPath engine.
=end item

=begin item
first

    say $tags.first('Document/L[1]/@O').name;

Like find, except the first matching node is returned.
=end item

=begin item
keys

   say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

returns the names of the nodes immediate children and attributes (prefixed by '@');
=end item

=begin item
Hash

Returns a Hash of child nodes (arrays of lists) and attrbiutes (prefixed by '@')

   say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
   say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute
=end item

=end pod
