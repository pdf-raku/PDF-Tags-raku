[[Raku PDF Project]](https://pdf-raku.github.io)
 / [[PDF-Tags Module]](https://pdf-raku.github.io/PDF-Tags-raku)
 / [PDF::Tags](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags)
 :: [XML-Writer](https://pdf-raku.github.io/PDF-Tags-raku/PDF/Tags/XML-Writer)

class PDF::Tags::XML-Writer
---------------------------

XML Serializer for tagged PDF structural items

Synopsis
--------

    use PDF::Class;
    use PDF::Tags;
    use PDF::Tags::XML-Writer;
    my PDF::Class $pdf .= open: "t/write-tags.pdf";
    my PDF::Tags $tags .= read: :$pdf;
    my PDF::Tags::XML-Writer $xml-writer .= new: :debug, :root-tag<Docs>;
    # atomic write
    say $xml-writer.Str($tags);
    # streamed write
    $xml-writer.say($*OUT, $tags);
    # do our own streaming
    for gather $xml-writer.stream-xml($tags) {
        $*OUT.print($_);
    }

Description
-----------

This class is used to dump nodes and their children in an XML format.

The `xml` method can be called on individual elements in the tree to dump these as fragments:

    say '<Document>';
    say .xml(:depth(2)) for $tags.find('Document//Sect');
    say '</Document>';

Calling `$node.xml(|c)`, is equivalent to: `PDF::Tags::XML-Writer.new(|c).Str($node)`

