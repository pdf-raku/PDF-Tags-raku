unit module PDF::Tags::XPath::Axes;

use PDF::Tags::Attr;
use PDF::Tags::Node;
use PDF::Tags::Node::Parent;

sub child(PDF::Tags::Node:D $_) is export { .?kids // [] }

sub ancestor-or-self(PDF::Tags::Node:D $_) is export {
    ancestor($_).push: $_;
 }

sub ancestor(PDF::Tags::Node:D $_) is export {
    my @nodes = ancestor-or-self($_)
        with .?parent;
    @nodes
}

sub descendant-or-self(PDF::Tags::Node:D $_) is export {
    descendant($_).unshift: $_;
}

sub attempt(&action) is hidden-from-backtrace {
    CATCH { default { warn $_ } }
    &action();
}

sub descendant(PDF::Tags::Node:D $_) is export {
    my @nodes;
     attempt({@nodes.append: descendant-or-self($_)})
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
    .?parent // [];
}

sub self(PDF::Tags::Node:D $_) is export {
    [ $_ ];
}

proto attribute(PDF::Tags::Node:D) is export {*}
multi attribute(PDF::Tags::Node::Parent:D $_) {
    given .root -> $root {
        [ .attributes.sort.map: -> $cos {PDF::Tags::Attr.new: :$cos, :parent($_), :$root} ]
    }
}

multi attribute(PDF::Tags::Node:D $_) {
    []
}
