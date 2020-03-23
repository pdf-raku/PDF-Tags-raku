unit class PDF::Tags::XML-Writer;

use PDF::Annot;
use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Item;
use PDF::Tags::ObjRef;
use PDF::Tags::Root;
use PDF::Tags::Mark;
use PDF::Tags::Text;
use PDF::Tags::XPath;
use PDF::Class::StructItem;

has UInt $.max-depth = 16;
has Bool $.render = True;
has Bool $.atts = True;
has $.css = '<?xml-stylesheet type="text/css" href="https://raw.githubusercontent.com/p6-pdf/PDF-Tags-raku/master/resources/tagged-pdf.css"?>';
has Bool $.debug = False;
has Str  $.omit;

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

method Str(PDF::Tags::Item $item) {
    my @chunks = gather { self.stream-xml($item, :depth(0)) };
    @chunks.join;
}

method print(IO::Handle $fh, PDF::Tags::Item $item) {
    for gather self.stream-xml($item, :depth(0)) {
        $fh.print($_);
    }
}
method say(IO::Handle $fh, PDF::Tags::Item $item) {
    self.print($fh, $item);
    $fh.say: '';
}

multi method stream-xml(PDF::Tags::Root $_, :$depth!) {
    take line(0, '<?xml version="1.0" encoding="UTF-8"?>');
    take line(0, $!css) if $!css;

    if .elems {
        warn "Tagged PDF has multiple top-level tags" if .elems > 1;
        self.stream-xml($_, :$depth) for .kids;
    }
    else {
        warn "Tagged PDF has no content";
    }
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
        with $node.actual-text {
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
    if $!render {
        take line($depth, trim(self!marked-content($node, :$depth)));
    }
}

multi method stream-xml(PDF::Tags::Text $_, :$depth!) {
    take line($depth, html-escape(.Str));
}

method !marked-content(PDF::Tags::Mark $node, :$depth!) is default {
    my $text = $node.actual-text // do {
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
=end pod
