class PDF::Tags::XPath
----------------------

Tiny XPath like search/navigation evaluator

Synopsis
--------

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

Description
-----------

PDF::Tags::XPath is an XPath like evaluator used to search for or to navigate between nodes. It is used to handle the `find` and `first` method available on all nodes and the `AT-KEY` method available on parent nodes (objects of type PDF::Tags, PDF::Tags::Element and PDF::Tags::Mark).

It implements a subset of the XPath axes, functions and data-types and includes some extensions to accommodate specifics of the Tagged PDF format.

### Axes

Examples:

    $node.first('parent::*'); # locate parent node
    $node.first('..'); # locate parent node
    for $node.find('following-sibling::P') {...} # process following paragraphs

The following XPath Axes are supported:

  * `ancestor::` - all ancestors (parent, grandparent, etc.) of the current node

  * `ancestor-or-self::` - the current node and all ancestors (self, parent, grandparent, etc.)

  * `attributes::` (or `@`) - all attributes of the current node

  * `child::` (default axis) - all children of the current node

  * `descendant::` - all descendants (children, grandchildren, etc.) of the current node

  * `descendant-or-self::` - the current node and it descendants (self, children, grandchildren, etc.)

  * `following::` - everything in the document after the current node

  * `following-sibling::` - all siblings after the current node

  * `preceding::` - everything in the document before the current node

  * `preceding-sibling::` - all siblings before the current node

  * `self::` (or `.`) - the current node

  * `parent::` (or `..`) - the current node's parent

### Node Tests

Examples:

    for $tags.find('//mark()') { ... }; # match all marked content references

  * `<ident>` - Match node name

  * `*` - Match all element nodes

  * `text()` - Match text nodes

  * `mark()` - (Extension) Match marked content references

  * `object()` - (Extension) Match object references

### Predicate Functions:

Examples:

    for $elem.find('L/LI[first() or last()]') {...}; # first and last list items 
    for $elem.find('L/LI[position() >= 3]') {... };  # third list item onward

  * `position()` - current position in parent list, numbered from `1`

  * `first()` - true if this is the first item in its parent list

  * `last()` - true if this is the first item in its parent list

### Predicate Operators

Loosest to tightest:

  * `or`

  * `and`

  * `=` `!=`

  * `<=`, `>=`

