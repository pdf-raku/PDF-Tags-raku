use PDF::Tags::Node;
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
=head1 NAME

PDF::Tags::Attr - Attribute node

=head1 DESCRIPTION

Objects of this class hold a single attribute value.

Note that attributes values may contain numbers, strings or arrays as below:

=begin table
cos type | example
====================
name | Placement=Block
number | Height=258
array | BBox=34 474 564 738
=end table

=head1 METHODS

=begin item
name

The attribute name, e.g. `BBox`.
=end item

=begin item
value

The value of the attribute either a string, a number, or an array of numbers.
=end item

=begin item
Str / text

The value as a text string. In the case of an array, the values are space seperated.
=end item

=begin item
gist

    say $table-elem<@BBox>.gist; # BBox=34 474 564 738

`$elem.gist` is equivalent to `$elem.name ~ '=' ~ $elem.text`
=end item

=begin item
parent

The parent node; of type PDF::Tags::Elem, or PDF::Tags::Mark
=end item

=end pod
