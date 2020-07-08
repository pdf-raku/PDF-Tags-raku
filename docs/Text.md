class PDF::Tags::Text
---------------------

Derived Text node

Description
-----------

Objects of this class hold derived text.

Attributes and Methods
----------------------

### has PDF::Tags::Node::Parent $.parent

The parent node

of type PDF::Tags::Elem, or PDF::Tags::Mark

### method name

```perl6
method name() returns Mu
```

Node name (always '#text')

### method cos

```perl6
method cos() returns Str
```

Text content

