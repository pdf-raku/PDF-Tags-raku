NAME
====

PDF::Tags::Node - Abstract node class

DESCRIPTION
===========

Abstract node ancestor class.

METHODS
=======

  * cos

    Returns the underlying PDF::Class or PDF::Content object. The PDF::Tags::Node subclass and PDF::COS type are interdependant:

    <table class="pod-table">
    <thead><tr>
    <th>PDF::Tags:Node object</th> <th>PDF::Class object |Base class</th> <th>Notes</th> <th></th>
    </tr></thead>
    <tbody>
    <tr> <td>PDF::Tags</td> <td>PDF::StructTreeRoot</td> <td>PDF::Tags::Node::Parent</td> <td>PDF structure tree root</td> </tr> <tr> <td>PDF::Tags::Elem</td> <td>PDF::StructElem</td> <td>PDF::Tags::Node::Parent</td> <td>Intermediate structure element node</td> </tr> <tr> <td>PDF::Tags::Mark</td> <td>PDF::MCR</td> <td>PDF::Tags::Parent</td> <td>Leaf marked content reference</td> </tr> <tr> <td>PDF::Tags::ObjRef</td> <td>PDF::OBJR</td> <td>PDF::Tags::Node</td> <td>Leaf object reference</td> </tr> <tr> <td>PDF::Tags::Text</td> <td>N/A</td> <td>PDF::Tags::Node</td> <td>Looking to eliminate this class?</td> </tr>
    </tbody>
    </table>

  * root

    Link to the structure tree root.

  * find / AT-KEY

        say $tags.find('Document/L[1]/@O')[0].name'
        say $tags<Document/L[1]/@O>[0].name'

    This method evaluates an XPath like expression (see PDF::Tags::XPath) and returns a list of matching nodes.

    With the exception that `$node.AT-KEY($node-name)` routes to `$node.Hash{$node-name}`, rather than using the XPath engine.

  * first

        say $tags.first('Document/L[1]/@O').name;

    Like find, except the first matching node is returned.

  * xml

    Serialize a node and any descendants as XML.

    Calling `$node.xml(|c)`, is equivalant to: `PDF::Tags::XML-Writer.new(|c).Str`

