[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Node](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node)
 :: [Parent](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node/Parent)

NAME
====

Pod::To::Markdown - Render Pod as Markdown

SYNOPSIS
========

From command line:

    $ perl6 --doc=Markdown lib/To/Class.pm

From Perl6:

```perl6
use Pod::To::Markdown;

=NAME
foobar.pl

=SYNOPSIS
    foobar.pl <options> files ...

print pod2markdown($=pod);
```

EXPORTS
=======

    class Pod::To::Markdown
    sub pod2markdown

DESCRIPTION
===========



### method render

```perl6
method render(
    $pod,
    Bool :$no-fenced-codeblocks
) returns Str
```

Render Pod as Markdown

To render without fenced codeblocks (```` ``` ````), as some markdown engines don't support this, use the :no-fenced-codeblocks option. If you want to have code show up as ```` ```perl6```` to enable syntax highlighting on certain markdown renderers, use:

    =begin code :lang<perl6>

### sub pod2markdown

```perl6
sub pod2markdown(
    $pod,
    Bool :$no-fenced-codeblocks
) returns Str
```

Render Pod as Markdown, see .render()

LICENSE
=======

This is free software; you can redistribute it and/or modify it under the terms of The [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).
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

Unlike the `Array` and `Hash` methods `kids` does not cache child elements and may be more efficient for one-off traversal of larger DOMs. 

### method keys

    say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

returns the names of the nodes immediate children and attributes (prefixed by '@');

### method Hash

Returns a Hash of child nodes (arrays of lists) and attributes (prefixed by '@')

    say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
    say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute

