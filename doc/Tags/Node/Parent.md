NAME
====

PDF::Tags::Node::Parent - Abstract non-leaf node

DESCRIPTION
===========

This is a base class for nodes that may contain child elements (objects of type: PDF::Tags, PDF::Tags::Elem and PDF::Tags::Mark).

METHODS
=======

  * AT-POS

        my $third-child = $node[2];

    `node[$n]` is equivalent to `node.kids[$n]`.

  * Array

    Returns all child nodes as an array.

  * kids

    Returns an iterator for the child elements:

        for $node.kids -> PDF::Tags::Node $kid { ... }
        my @kids = $node.kids;  # consume all at once

    Unlike the `Array` and `Hash` methods `kids` does not cache child elements and may be ore efficient for one-off traversal of larger DOMs. 

  * find / AT-KEY

        say $tags.find('Document/L[1]/@O')[0].name'
        say $tags<Document/L[1]/@O>[0].name'

    This method evaluates an XPath like expression (see PDF::Tags::XPath) and returns a list of matching nodes.

    With the exception that `$node.AT-KEY($node-name)` routes to `$node.Hash{$node-name}`, rather than using the XPath engine.

  * first

        say $tags.first('Document/L[1]/@O').name;

    Like find, except the first matching node is returned.

  * keys

        say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

    returns the names of the nodes immediate children and attributes (prefixed by '@');

  * Hash

    Returns a Hash of child nodes (arrays of lists) and attrbiutes (prefixed by '@')

        say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
        say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute

