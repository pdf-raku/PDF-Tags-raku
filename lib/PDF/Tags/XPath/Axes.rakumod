unit module PDF::Tags::XPath::Axes;

use PDF::Tags::Attr;
use PDF::Tags::Node;

sub child(PDF::Tags::Node:D $_) is export { .?kids // [] }

sub ancestor-or-self(PDF::Tags::Node:D $_) is export {
    my @nodes = ancestor-or-self($_)
        with .?parent;
    @nodes.push: $_;
 }

sub ancestor(PDF::Tags::Node:D $_) is export {
    my @nodes = ancestor-or-self($_)
        with .?parent;
    @nodes;
}

sub descendant-or-self(PDF::Tags::Node:D $_) is export {
    my @nodes = $_;
    @nodes.append: descendant-or-self($_)
        for .?kids // [];
    @nodes;
}

sub descendant(PDF::Tags::Node:D $_) is export {
    my @nodes;
    @nodes.append: descendant-or-self($_)
        for .?kids // [];
    @nodes;
}

sub following(PDF::Tags::Node:D $item) is export {
    my @nodes;
    with $item.?parent {
        for .kids {
            if ($_ === $item) ^ff * {
                @nodes.append: descendant-or-self($_);
            }
        }
    }
    @nodes;
}

sub following-sibling(PDF::Tags::Node:D $item) is export {
    my @nodes;
    with $item.?parent {
        for .kids {
            if ($_ === $item) ^ff * {
                @nodes.push: $_;
            }
        }
    }
    @nodes;
}

sub preceding(PDF::Tags::Node:D $item) is export {
    my @nodes;
    with $item.?parent -> $parent {
        for ^$parent.elems {
            with $parent[$_] {
                last if $_ === $item;
                @nodes.append: descendant-or-self($_);
            }
        }
    }
    @nodes.reverse;
}

sub preceding-sibling(PDF::Tags::Node:D $item) is export {
    my @nodes;
    with $item.?parent -> $parent {
        for ^$parent.elems {
            with $parent[$_] {
                last if $_ === $item;
                @nodes.push: $_;
            }
        }
    }
    @nodes.reverse;
}

sub parent(PDF::Tags::Node:D $_) is export {
    with .?parent { [ $_ ] } else { [] }
}

sub self(PDF::Tags::Node:D $_) is export {
    [ $_ ];
}

sub attribute(PDF::Tags::Node:D $_) is export {
    if .can('attributes') {
        my $root := .root;
        [ .attributes.sort.map: -> $cos {PDF::Tags::Attr.new: :$cos, :parent($_), :$root} ]
    }
    else {
        [];
    }
}
