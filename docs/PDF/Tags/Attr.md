[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [Attr](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/Attr)

class PDF::Tags::Attr
---------------------

Attribute node

Description
-----------

Objects of this class hold a single attribute value.

Note that attributes values may contain numbers, strings or arrays as below:

<table class="pod-table">
<thead><tr>
<th>cos type</th> <th>example</th>
</tr></thead>
<tbody>
<tr> <td>name</td> <td>Placement=Block</td> </tr> <tr> <td>number</td> <td>Height=258</td> </tr> <tr> <td>array</td> <td>BBox=34 474 564 738</td> </tr>
</tbody>
</table>

Methods
-------

### name

    method name() returns Str

The attribute name, e.g. `BBox`.

### value

    method value() returns Any

The value of the attribute either a string, a number, or an array of numbers.

### method Str (alias text)

    method Str() returns Str

The value as a text string. In the case of an array, the values are space separated.

### method gist

    method gist returns Str
    say $table-elem<@BBox>.gist; # BBox=34 474 564 738

`$elem.gist` is equivalent to `$elem.name ~ '=' ~ $elem.text`

### method parent

    method parent returns PDF::Tags::Node::Parent

The parent node; of type PDF::Tags, PDF::Tags::Elem, or PDF::Tags::Mark

