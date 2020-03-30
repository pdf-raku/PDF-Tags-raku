use PDF::Tags::Node :&node-class, :&build-node;

class PDF::Tags::Node::Parent
    is PDF::Tags::Node {

    use Method::Also;
    use PDF::COS;
    use PDF::StructElem;
    my subset NCName of Str where { !.defined || $_ ~~ /^<ident>$/ }

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
        my $kid := self.build-kid($cos, |c);
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
            %h;
        }
    }
    multi method AT-KEY(NCName:D $name) {
        # tag name
        self.Hash{$name};
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
