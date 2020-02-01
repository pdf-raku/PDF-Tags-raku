unit module PDF::Tags::XPath::Axis;

use PDF::Tags::Item;

sub child(PDF::Tags::Item:D $_) is export { .?kids // [] }

sub ancestor-or-self(PDF::Tags::Item:D $_) is export {
    my @nodes = ancestor-or-self($_)
        with .?parent;
    @nodes.push: $_;
 }

sub ancestor(PDF::Tags::Item:D $_) is export {
    my @nodes = ancestor-or-self($_)
        with .?parent;
    @nodes;
}

sub descendant-or-self(PDF::Tags::Item:D $_) is export {
    my @nodes = $_;
    @nodes.append: descendant-or-self($_)
        for .?kids // [];
    @nodes;
}

sub descendant(PDF::Tags::Item:D $_) is export {
    my @nodes;
    @nodes.append: descendant-or-self($_)
        for .?kids // [];
    @nodes;
}

sub following(PDF::Tags::Item:D $item) is export {
    my @nodes;
    with $item.?parent {
        my @kids = .kids;
        my Bool $following;
        for @kids {
            when $following { @nodes.append: descendant-or-self($_) }
            when $_ === $item { $following = True }
        }
    }
    @nodes;
}

sub following-sibling(PDF::Tags::Item:D $item) is export {
    my @nodes;
    with $item.?parent {
        my @kids = .kids;
        my Bool $following;
        for @kids {
            when $following { @nodes.push: $_ }
            when $_ === $item { $following = True }
        }
    }
    @nodes;
}

sub preceding(PDF::Tags::Item:D $item) is export {
    my @nodes;
    with $item.?parent -> $parent {
        for 0 ..^ $parent.elems {
            with $parent[$_] {
                last if $_ === $item;
                @nodes.append: descendant-or-self($_);
            }
        }
    }
    @nodes.reverse;
}

sub preceding-sibling(PDF::Tags::Item:D $item) is export {
    my @nodes;
    with $item.?parent -> $parent {
        for 0 ..^ $parent.elems {
            with $parent[$_] {
                last if $_ === $item;
                @nodes.push: $_;
            }
        }
    }
    @nodes.reverse;
}

sub parent(PDF::Tags::Item:D $_) is export {
    with .?parent { [ $_ ] } else { [] }
}

sub self(PDF::Tags::Item:D $_) is export {
    [ $_ ];
}
