unit class PDF::Tags::XML-Writer;

use PDF::Annot;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Node;
use PDF::Tags::ObjRef;
use PDF::Tags::Node::Root;
use PDF::Tags::Mark;
use PDF::Tags::Text;
use PDF::Tags::XPath;
use PDF::Class::StructItem;

has UInt $.max-depth = 16;
has Bool $.atts = True;
has $.css = '<?xml-stylesheet type="text/css" href="https://p6-pdf.github.io/css/tagged-pdf.css"?>';
has Bool $.style = True;
has Bool $.debug = False;
has Str  $.omit;
has Str  $.root-tag;

sub line(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s ~ "\n" }

sub html-escape(Str $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
        
}
multi sub str-escape(@a) { @a.map({str-escape($_)}).join: ' '; }
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
        warn "Tagged PDF has no content; no :root-tag given"
            unless $!root-tag.defined;
    }
    take line(--$depth, '</' ~ $_ ~ '>')
        with $!root-tag;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        take line($depth, "<!-- elem {.obj-num} {.gen-num} R -->")
            given $node.cos;
    }
    my $name = $node.name;
    my $att = do if $!atts {
        my %attributes = $node.attributes;
        %attributes<O>:delete;
        atts-str(%attributes);
    }
    else {
        $name = $_
            with $node.dom.role-map{$name};
        ''
    }
    my $omit-tag = $name ~~ $_ with $!omit;

    if $depth >= $!max-depth {
        take line($depth, "<$name$att/> <!-- depth exceeded, see {$node.cos.obj-num} {$node.cos.gen-num} R -->");
    }
    else {
        with $node.ActualText {
            take line($depth, '<!-- actual text -->')
                if $!debug;
            given html-escape(trim($_)) -> $text {
                if $omit-tag {
                    take $text;
                }
                else {
                    take $_ eq ''
                        ?? line($depth, "<$name$att/>")
                        !! line($depth, "<$name$att>{$text}</$name>");
                }
            }
        }
        else {
            my $elems = $node.elems;
            if $elems {
                take line($depth++, "<$name$att>")
                    unless $omit-tag;
        
                for 0 ..^ $elems {
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
    take line($depth, "<!-- OBJR {.object.obj-num} {.object.gen-num} R -->")
        if $!debug;
##     take self.stream-xml($_, :$depth) with .parent;
}

multi method stream-xml(PDF::Tags::Mark $node, :$depth!) {
    if $!debug {
        take line($depth, "<!-- mark MCID:{.mcid} Pg:{.owner.obj-num} {.owner.gen-num} R-->")
            given $node.mark;
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
            default { die "unhandled tagged content: {.WHAT.perl}"; }
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

=head1 NAME

PDF::Tags::XML-Writer - XML Serializer for tagged PDF structural items

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class is used to dump nodes and their children in an XML format.

The `xml` method can be called on individual elements in the tree to
dump these as fragments:

   say '<Document>';
   say .xml(:depth(2)) for $tags.find('Document//Sect');
   say '</Document>';

Calling `$node.xml(|c)`, is equivalant to: `PDF::Tags::XML-Writer.new(|c).Str`

=end pod
