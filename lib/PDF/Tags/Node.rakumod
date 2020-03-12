use PDF::Tags::Item :&item-class, :&build-item;

class PDF::Tags::Node
    is PDF::Tags::Item {

    use PDF::StructElem;
    my subset NCName of Str where { !.defined || $_ ~~ /^<ident>$/ }

    has PDF::Tags::Item @.kids;
    method kids-raw { @!kids }
    has Hash $!store;
    has Bool $!loaded;
    has UInt $!elems;

    method elems {
        $!elems //= do with $.value.kids {
            when Hash { 1 }
            default { .elems }
        } // 0;
    }

    method build-kid($value, :$Pg = $.Pg) { build-item($value, :parent(self), :$Pg, :$.root); }
    multi method add-kid(PDF::Tags::Node:D $node) {
        die "node already parented"
            with $node.parent;
        die "unable to add a node to itself"
            if $node === self || $node.value === $node.parent.value;

        $node.parent = self;
        @!kids.push: $node;
    }
    multi method add-kid(Str:D $name) {
        my $P := self.value;
        my PDF::StructElem $value = PDF::COS.coerce: %(
            :Type( :name<StructElem> ),
            :S( :$name ),
            :$P,
        );
        self.add-kid($value)
    }
    multi method add-kid($value, |c ) is default {
        my $kid := self.build-kid($value, |c);
        given self.value.kids //= [] {
            $_ = [$_] if $_ ~~ Hash;
            .push($kid.value);
        }
        @!kids.push: $kid;
        $kid;
    }
    method AT-POS(UInt $i) {
        fail "index out of range 0 .. $.elems: $i" unless 0 <= $i < $.elems;
        @!kids[$i] //= self.build-kid($.value.kids[$i]);
    }
    method Array {
        $!loaded ||= do {
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
        $!store;
    }
    multi method AT-KEY(NCName:D $name) {
        # special case to handle default namespaces without a prefix.
        # https://stackoverflow.com/questions/16717211/
        self.Hash{$name};
    }
    multi method AT-KEY(Str:D $xpath) is default {
        $.xpath-context.AT-KEY($xpath);
    }
    method kids {
        my class Kids does Iterable does Iterator does Positional {
            has PDF::Tags::Item $.node is required handles<elems AT-POS>;
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

    multi method ACCEPTS(PDF::Tags::Node:D: Str $xpath) {
        ? self.find($xpath);
    }
    multi method ACCEPTS(PDF::Tags::Node:D: Code $xpath) {
        ? self.find($xpath);
    }
}
