NAME
====

PDF::Tags::Attr - Attribute node

DESCRIPTION
===========

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

METHODS
=======

  * name

    The attribute name, e.g. `BBox`.

  * value

    The value of the attribute either a string, a number, or an array of numbers.

  * Str / text

    The value as a text string. In the case of an array, the values are space separated.

  * gist

        say $table-elem<@BBox>.gist; # BBox=34 474 564 738

    `$elem.gist` is equivalent to `$elem.name ~ '=' ~ $elem.text`

  * parent

    The parent node; of type PDF::Tags::Elem, or PDF::Tags::Mark

