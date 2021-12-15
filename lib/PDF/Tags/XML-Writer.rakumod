#| XML Serializer for tagged PDF structural items
unit class PDF::Tags::XML-Writer;

use PDF::Annot;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Node;
use PDF::Tags::ObjRef;
use PDF::Tags::Node::Parent;
use PDF::Tags::Node::Root;
use PDF::Tags::Mark;
use PDF::Tags::Text;
use PDF::Tags::XPath;
use PDF::Class::StructItem;

has UInt $.max-depth = 16;
has Bool $.atts = True;
has $.css = '<?xml-stylesheet type="text/css" href="https://pdf-raku.github.io/css/tagged-pdf.css"?>';
has Bool $.style = True;
has Bool $.debug = False;
has Bool $.marks;
has Str  $.omit = 'Span';
has Str  $.root-tag;

sub line(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s ~ "\n" }

sub html-escape(Str $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
        
}
multi sub str-escape(@a) { @a.map(&str-escape).join: ' '; }
multi sub str-escape(Str $_) {
    html-escape($_).trans: /\"/ => '&quote;';
}
multi sub str-escape(Pair $_) { str-escape(.value) }
multi sub str-escape($_) is default { str-escape(.Str) }

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{str-escape(.value)}\"" }).join;
}

method Str(PDF::Tags::Node $item) {
    my @chunks = gather { self.stream-xml($item, :depth(0)) };
    @chunks.join;
}

method print(IO::Handle $fh, PDF::Tags::Node $item, :$depth = 0) {
    for gather self.stream-xml($item, :$depth) {
        $fh.print($_);
    }
}
method say(IO::Handle $fh, PDF::Tags::Node $item, :$depth = 0) {
    self.print($fh, $item, :$depth);
    $fh.say: '';
}

multi method stream-xml(PDF::Tags::Node::Root $_, UInt :$depth is copy = 0) {
    take line($depth, '<?xml version="1.0" encoding="UTF-8"?>');
    take line($depth, $!css) if $!style;

    take line($depth++, '<' ~ $_ ~ '>')
        with $!root-tag;

    if .elems {
        die "Tagged PDF has multiple top-level tags; no :root-tag given"
            if .elems > 1 && ! $!root-tag.defined;
        self.stream-xml($_, :$depth) for .kids;
    }
    else {
        warn "Tagged PDF has no content and no :root-tag has been given"
            unless $!root-tag.defined;
    }
    take line(--$depth, '</' ~ $_ ~ '>')
        with $!root-tag;
}

method !actual-text($node) {
    my $actual-text = $node.ActualText
        if $node ~~ PDF::Tags::Node::Parent;
    $actual-text //= $node.kids.map({ .cos.ActualText }).join
        if $node ~~ PDF::Tags::Node::Parent
        && !$node.kids.first: { ! (.name ~~ $!omit && .cos.ActualText.defined)};
    $actual-text;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        take line($depth, "<!-- elem {.obj-num} {.gen-num} R -->")
            given $node.cos;
    }
    my $name = $node.name;
    my $actual-text = self!actual-text($node);
    my $att = do if $!atts {
        my %attributes = $node.attributes;
        %attributes<O>:delete;
        if $!marks {
            %attributes<ActualText> = $_ with $actual-text;
        }
        atts-str(%attributes);
    }
    else {
        $name = $_
            with $node.dom.role-map{$name};
        ''
    }
    my $omit-tag = $name ~~ $_ with $!omit;

    if $depth >= $!max-depth {
        take line($depth, "<$name> <!-- depth exceeded, see {$node.cos.obj-num} {$node.cos.gen-num} R -->");
    }
    else {
        with $actual-text {
            if $!debug {
                if $!marks {
                    take line($depth, "<!-- actual text: {.raku} -->")
                }
                else {
                    take line($depth, '<!-- actual text -->');
                }
            }
            
            $node.attributes<ActualText> = $_;

            my $frag = do given html-escape(trim($_)) {
                when $omit-tag { $_ }
                when .so       { '<%s%s>%s</%s>'.sprintf: $name, $att, $_, $name }
                default        { '<%s%s/>'.sprintf: $name, $att }
            }
            take line($depth, $frag);
        }
        if $!marks || !$actual-text.defined {
            # descend
            my $elems = $node.elems;
            if $elems {
                take line($depth++, "<$name$att>")
                    unless $omit-tag;
        
                for ^$elems {
                    my $kid = $node.kids[$_];
                    self.stream-xml($kid, :$depth);
                }

                take line(--$depth, "</$name>")
                     unless $omit-tag;
            }
            else {
                take line($depth, "<$name$att/>")
                    unless $omit-tag;
            }
        }
    }
}

multi method stream-xml(PDF::Tags::ObjRef $_, :$depth!) {
    take line($depth, "<!-- OBJR {.cos.obj-num} {.cos.gen-num} R -->")
        if $!debug;
##     take self.stream-xml($_, :$depth) with .parent;
}

multi method stream-xml(PDF::Tags::Mark $node, :$depth!) {
    if $!debug {
        take line($depth, "<!-- mark MCID:{.mcid} Pg:{.canvas.obj-num} {.canvas.gen-num} R-->")
            given $node.value;
    }
    take line($depth, trim(self!marked-content($node, :$depth)));
}

multi method stream-xml(PDF::Tags::Text $_, :$depth!) {
    take line($depth, html-escape(.Str));
}

method !marked-content(PDF::Tags::Mark $node, :$depth!) is default {
    my $text = $node.ActualText // do {
        my @text = $node.kids.map: {
            when PDF::Tags::Mark {
                my $text = self!marked-content($_, :$depth);
            }
            when PDF::Tags::Text { html-escape(.Str) }
            default { die "unhandled tagged content: {.WHAT.raku}"; }
        }
        @text.join;
    }

    my $name := $node.name;
    my $omit-tag = $name ~~ $_ with $!omit;

    if $omit-tag {
        $text;
    }
    else {
        my $atts := atts-str($node.attributes);
        "\<$name$atts" ~ ($text ?? "\>$text\</$name\>" !! '/>');
    }
}

=begin pod

=head2 Synopsis

    use PDF::Class;
    use PDF::Tags;
    use PDF::Tags::XML-Writer;
    my PDF::Class $pdf .= open: "t/pdf/write-tags.pdf";
    my PDF::Tags $tags .= read: :$pdf;
    my PDF::Tags::XML-Writer $xml-writer .= new: :debug, :root-tag<Docs>;
    # atomic write
    say $xml-writer.Str($tags);
    # streamed write
    $xml-writer.say($*OUT, $tags);
    # do our own streaming
    for gather self.stream-xml($item) {
        $*OUT.print($_);
    }

=head2 Description

This class is used to dump nodes and their children in an XML format.

The `xml` method can be called on individual elements in the tree to
dump these as fragments:

   say '<Document>';
   say .xml(:depth(2)) for $tags.find('Document//Sect');
   say '</Document>';

Calling `$node.xml(|c)`, is equivalent to: `PDF::Tags::XML-Writer.new(|c).Str($node)`

=end pod
