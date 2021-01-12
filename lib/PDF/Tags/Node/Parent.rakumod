use PDF::Tags::Node :&node-class, :&build-node, :TagName;

#| Abstract non-leaf node
class PDF::Tags::Node::Parent
    is PDF::Tags::Node {

    use Method::Also;
    use PDF::COS;
    use PDF::StructElem;
    use PDF::Content::Tag :TagSet, :%TagAliases;

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

        # re-parent cos node
        given self.cos.kids //= [] {
            $_ = [$_] if $_ ~~ Hash;
            $node.cos.P = self.cos
                if $node.cos ~~ PDF::StructElem;
            .push($node.cos);
        }

        # re-parent dom node
        $node.parent = self;
        @!kids.push: $node;

        # update caches
        $!elems = Nil;
        self.AT_POS($.elems-1) if $!reified;
        .{$node.name}.push: $node with $!store;

        $node;
    }
    multi method add-kid(PDF::Tags::Node:D :$node!) {
        self!adopt-node($node);
    }
    multi method add-kid(Str:D :$name!, *%o) {
        my $P := self.cos;
        my PDF::StructElem $cos .= COERCE: %(
            :Type( :name<StructElem> ),
            :S( :$name ),
            :$P,
        );
        self.add-kid(:$cos, |%o)
    }
    multi method add-kid(:$cos!, *%o) {
        my PDF::Tags::Node $kid := self.build-kid($cos, |%o);
        self!adopt-node($kid);
    }
    multi method FALLBACK(Str:D $name where $_ ∈ TagSet, |c) {
        self.add-kid(:$name, |c)
    }
    multi method FALLBACK(Str:D $_ where (%TagAliases{$_}:exists), |c) {
        my Str:D $name = %TagAliases{$_};
        self.add-kid(:$name, |c)
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
        $val;
    }
    multi method AT-KEY(TagName:D $name) {
        # tag name
        @(self.Hash{$name} // []);
    }
    multi method AT-KEY(Str:D $xpath) is default {
        $.xpath-context.AT-KEY($xpath);
    }

    method kids {
        my class Kids does Iterable does Positional {
            has PDF::Tags::Node $.node is required handles<elems AT-POS Numeric>;
            method Array handles<List list values map grep> { $!node.Array }
            method iterator {
                class Iteration does Iterator {
                    has UInt $!idx = 0;
                    has PDF::Tags::Node::Parent $.node is required;
                    method pull-one {
                        if $!idx < $!node.elems {
                            $!node.AT-POS($!idx++);
                        }
                        else {
                            IterationEnd;
                        }
                    }
                }
                Iteration.new: :$.node;
            }
        }
        Kids.new: :node(self);
    }

}

=begin pod

=head2 Description

This is a base class for nodes that may contain child elements (objects of type:
PDF::Tags, PDF::Tags::Elem and PDF::Tags::Mark).

=head2 Methods

=head3 method AT-POS

    method AT-POS(UInt $index) returns PDF::Tags::Node
    my $third-child = $node[2];

`node[$n]` is equivalent to `node.kids[$n]`.

=head3 method Array

Returns all child nodes as an array.

=head3 method kids

Returns an iterator for the child elements:

    for $node.kids -> PDF::Tags::Node $kid { ... }
    my @kids = $node.kids;  # consume all at once

Unlike the `Array` and `Hash` methods `kids` does not cache child elements
and may be more efficient for one-off traversal of larger DOMs.    

=head3 method keys

   say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

returns the names of the nodes immediate children and attributes (prefixed by '@');

=head3 method Hash

Returns a Hash of child nodes (arrays of lists) and attributes (prefixed by '@')

   say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
   say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute

=end pod
