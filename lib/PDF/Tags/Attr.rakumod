use PDF::Tags::Node;
#| Attribute node
class PDF::Tags::Attr
    is PDF::Tags::Node {
    use PDF::Tags::Node::Parent;
    use Method::Also;

    has PDF::Tags::Node::Parent $.parent is rw;

    submethod TWEAK(Pair :$cos!) {
        self.set-cos($cos);
    }
    multi sub to-str(@a) { @a.map(*.Str).join: ' '}
    multi sub to-str($_) { .Str}
    method name { $.cos.key }
    method value { $.cos.value }
    method text is also<Str> { to-str($.value) }
    method gist { [~] '@', $.cos.key, '=', $.text }
    method cos(--> Pair) is also<kv> { callsame() }
}

=begin pod

=head2 Description

Objects of this class hold a single attribute value.

Note that attributes values may contain numbers, strings or arrays as below:

=begin table
cos type | example
====================
name | Placement=Block
number | Height=258
array | BBox=34 474 564 738
=end table

=head2 Methods
=head3 name

    method name() returns Str

The attribute name, e.g. `BBox`.

=head3 value

    method value() returns Any

The value of the attribute either a string, a number, or an array of numbers.

=head3 method Str (alias text)

    method Str() returns Str

The value as a text string. In the case of an array, the values are space separated.

=head3 method gist

    method gist returns Str
    say $table-elem<@BBox>.gist; # BBox=34 474 564 738

`$elem.gist` is equivalent to `$elem.name ~ '=' ~ $elem.text`

=head3 method parent

    method parent returns PDF::Tags::Node::Parent

The parent node; of type PDF::Tags, PDF::Tags::Elem, or PDF::Tags::Mark

=end pod
