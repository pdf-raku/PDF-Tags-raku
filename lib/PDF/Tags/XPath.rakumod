#| Tiny XPath like search/navigation evaluator
unit class PDF::Tags::XPath;

use PDF::Tags;
use PDF::Tags::Node;
use PDF::Tags::XPath::Grammar;
use PDF::Tags::XPath::Actions;
use Method::Also;

has PDF::Tags::Node $.node;

method compile(Str:D $expr --> Code) {
    my PDF::Tags::XPath::Actions $actions .= new;
    fail "can't handle xpath: $expr"
       unless PDF::Tags::XPath::Grammar.parse($expr, :$actions);
    $/.ast;
}

multi method find(Any $expr, PDF::Tags:D $dom) {
    $!node = $dom.root;
    self.find($expr);
}

multi method find(Any $expr, PDF::Tags::Node:D $!node) {
    self.find($expr);
}

multi method find(Str:D $xpath) is also<AT-KEY> {
    my PDF::Tags::XPath::Actions::Expression $expr := self.compile($xpath);
    self.find($expr);
}

multi method find(&expr --> Seq) {
    &expr($!node).Seq;
}

method first($expr is raw) {
    self.find($expr)[0] // PDF::Tags::Node;
}

=begin pod

=head2 Synopsis

    use PDF::Class;
    use PDF::Tags;
    use PDF::Tags::XPath;
    my PDF::Class $pdf .= open: "t/pdf/write-tags.pdf";
    my PDF::Tags $tags .= read: :$pdf;
    my PDF::Tags::XPath $xpath = $tags.xpath-context();
    say .name for $xpath.find('Document/L/LI[1]/*');
    # -OR-
    say .name for $tags.find('Document/L/LI[1]/*');
    # -OR-
    say .name for $tags<Document/L/LI[1]/*>;

=head2 Description

PDF::Tags::XPath is an XPath like evaluator used to search for or to navigate between nodes. It is used to
handle the `find` and `first` method available on all nodes and the `AT-KEY` method
available on parent nodes (objects of type PDF::Tags, PDF::Tags::Element and PDF::Tags::Mark).

It implements a subset of the XPath axes, functions and data-types and includes some
extensions to accommodate specifics of the Tagged PDF format.

=head3 Axes

Examples:

    $node.first('parent::*'); # locate parent node
    $node.first('..'); # locate parent node
    for $node.find('following-sibling::P') {...} # process following paragraphs

The following XPath Axes are supported:

=item `ancestor::` - all ancestors (parent, grandparent, etc.) of the current node
=item `ancestor-or-self::` - the current node and all ancestors (self, parent, grandparent, etc.)
=item `attributes::` (or `@`) - all attributes of the current node
=item `child::` (default axis) - all children of the current node
=item `descendant::` - all descendants (children, grandchildren, etc.) of the current node
=item `descendant-or-self::` - the current node and it descendants (self,  children, grandchildren, etc.)
=item `following::` - everything in the document after the current node
=item `following-sibling::` - all siblings after the current node
=item `preceding::` - everything in the document before the current node
=item `preceding-sibling::` - all siblings before the current node
=item `self::` (or `.`) - the current node
=item `parent::` (or `..`) - the current node's parent

=head3 Node Tests

Examples:

    for $tags.find('//mark()') { ... }; # match all marked content references

=item `<ident>` -  Match node name
=item `*` - Match all element nodes
=item `text()` - Match text nodes
=item `mark()` - (Extension) Match marked content references
=item `object()` - (Extension) Match object references

=head3 Predicate Functions:

Examples:

    for $elem.find('L/LI[first() or last()]') {...}; # first and last list items 
    for $elem.find('L/LI[position() >= 3]') {... };  # third list item onward

=item `position()` - current position in parent list, numbered from `1`
=item `first()` - true if this is the first item in its parent list
=item `last()` - true if this is the first item in its parent list

=head3 Predicate Operators

Loosest to tightest:

=item `or`
=item `and`
=item  `=` `!=`
=item `<=`, `>=`
                                                                   
=end pod

