[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Node](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node)
 :: [Parent](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node/Parent)

class PDF::Tags::Node::Parent
-----------------------------

Abstract non-leaf node

Description
-----------

This is a base class for nodes that may contain child elements (objects of type: PDF::Tags, PDF::Tags::Elem and PDF::Tags::Mark).

Methods
-------

### method AT-POS

    method AT-POS(UInt $index) returns PDF::Tags::Node
    my $third-child = $node[2];

`node[$n]` is equivalent to `node.kids[$n]`.

### method Array

Returns all child nodes as an array.

### method kids

Returns an iterator for the child elements:

    for $node.kids -> PDF::Tags::Node $kid { ... }
    my @kids = $node.kids;  # consume all at once

Unlike the `Array` and `Hash` methods `kids` does not cache child elements and may be ore efficient for one-off traversal of larger DOMs. 

### method keys

    say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

returns the names of the nodes immediate children and attributes (prefixed by '@');

### method Hash

Returns a Hash of child nodes (arrays of lists) and attrbiutes (prefixed by '@')

    say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
    say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute

