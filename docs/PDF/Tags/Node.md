[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Node](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Node)

class PDF::Tags::Node
---------------------

Abstract Node

Methods
-------

### method cos

Returns the underlying PDF::Class or PDF::Content object. The PDF::Tags::Node subclass and PDF::COS type are mapped as follows:

<table class="pod-table">
<thead><tr>
<th>PDF::Tags::Node object</th> <th>PDF::Class object |Base class</th> <th>Notes</th> <th></th>
</tr></thead>
<tbody>
<tr> <td>PDF::Tags</td> <td>PDF::StructTreeRoot</td> <td>PDF::Tags::Node::Parent</td> <td>PDF structure tree root</td> </tr> <tr> <td>PDF::Tags::Elem</td> <td>PDF::StructElem</td> <td>PDF::Tags::Node::Parent</td> <td>Intermediate structure element node</td> </tr> <tr> <td>PDF::Tags::Mark</td> <td>PDF::MCR</td> <td>PDF::Tags::Parent</td> <td>Leaf marked content reference</td> </tr> <tr> <td>PDF::Tags::ObjRef</td> <td>PDF::OBJR</td> <td>PDF::Tags::Node</td> <td>Leaf object reference</td> </tr> <tr> <td>PDF::Tags::Text</td> <td>N/A</td> <td>PDF::Tags::Node</td> <td>Looking to eliminate this class?</td> </tr>
</tbody>
</table>

### method root

    method root() returns PDF::Tags

Link to the structure tree root.

### method find (alias AT-KEY)

    method find is also<AT-KEY> returns Seq
    say $tags.find('Document/L[1]/@O')[0].name'
    say $tags<Document/L[1]/@O>[0].name'

This method evaluates an XPath like expression (see PDF::Tags::XPath) and returns a sequence of matching nodes.

With the exception that `$node.AT-KEY($node-name)` routes to `$node.Hash{$node-name}`, rather than using the XPath engine.

### method first

    method first($expr) returns PDF::Tags::Node
    say $tags.first('Document/L[1]/@O').name;

Like find, except the first matching node is returned.

### method xml

    method xml(*%opts) returns Str

Serialize a node and any descendants as XML.

Calling `$node.xml(|c)`, is equivalent to: `PDF::Tags::XML-Writer.new(|c).Str`

