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

This is a base class for nodes that may contain child elements (objects of type: [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags), [PDF::Tags::Elem](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Elem) and [PDF::Tags::Mark](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Mark)).

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

### method add-kid multi method add-kid(Str :$name!, *%atts) returns PDF::Tags::Node:D; multi method add-kid(PDF::Tags::Node:D :$node!) returns PDF::Tags::Node:D;

Adds the node as a child of the current node.

  * The `:$name` form creates a new empty child node with the given name and attributes

  * The `:$node` reparents an existing node as a child of the current node.

### method keys

    say $tags.first('Document/L[1]').keys.sort.join; # e.g.: '@ListNumbering,@O,LI'

returns the names of the nodes immediate children and attributes (prefixed by '@');

### method Hash

Returns a Hash of child nodes (arrays of lists) and attributes (prefixed by '@')

    say $tags.first('<Document/L[1]').Hash<LBody>[0].text;  # text of first list-item
    say $tags.first('<Document/L[1]').Hash<@ListNumbering>; # lit numbering attribute

### Alias methods

Standard structure tags and there aliases can be used as an alias for the `add-kid()` method. For example `$node.add-kid( :name(Paragraph) )` can be written as `$node.Paragraph`, or $node.P. The full list of alias methods is:

#### Structure Tags

Document, Part, Article(Art), Section(Sect), Division(Div), BlockQuotation(BlockQuote), Caption, TableOfContents(TOC), TableOfContentsItem(TOCI), Index, NonstructuralElement(NonStruct), PrivateElement(Private)

#### Paragraph Tags

Paragraph(P), Header(H), Header1(H1), Header2(H2), Header3(H3), Header4(H4), Header5(H5), Header6(H6),

#### List Element Tags

List(L), ListItem(LI), Label(Lbl), ListBody(LBody),

#### Table Tags

Table, TableRow(TR), TableHeader(TH), TableData(TD), TableBody(TBody), TableFooter(TFoot),

#### Inline Element Tags

Span, Quotation(Quote), Note, Reference, BibliographyEntry(BibEntry), Code, Link, Annotation(Annot), Ruby, RubyPunctutation(RP), RubyBaseText(RB), RubyText(RT), Warichu, WarichuPunctutation(RP), WarichuText(RT), Artifact,

#### Illustration Tags

Figure, Formula, Form

