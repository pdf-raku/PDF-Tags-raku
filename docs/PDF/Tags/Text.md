[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Text](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Text)

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

```raku
method name() returns Mu
```

Node name (always '#text')

### method Str

```raku
method Str() returns Str
```

Text content

