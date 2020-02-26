unit class PDF::Tags::XML;

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
    self.stream-xml($_, :$depth) for .kids;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        take line($depth, "<!-- elem {.obj-num} {.gen-num} R ({.WHAT.^name})) -->")
            given $node.value;
    }
    my $tag = $node.tag;
    my $att = do if $!atts {
        my %attributes = $node.attributes;
        %attributes<O>:delete;
        atts-str(%attributes);
    }
    else {
        $tag = $_
            with $node.dom.role-map{$tag};
        ''
    }
    my $omit-tag = $tag ~~ $_ with $!omit;

    if $depth >= $!max-depth {
        take line($depth, "<$tag$att/> <!-- depth exceeded, see {$node.value.obj-num} {$node.value.gen-num} R -->");
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
                        ?? line($depth, "<$tag$att/>")
                        !! line($depth, "<$tag$att>{$text}</$tag>");
                }
            }
        }
        else {
            my $elems = $node.elems;
            if $elems {
                take line($depth++, "<$tag$att>")
                    unless $omit-tag;
        
                for 0 ..^ $elems {
                    my $kid = $node.kids[$_];
                    self.stream-xml($kid, :$depth);
                }

                take line(--$depth, "</$tag>")
                     unless $omit-tag;
            }
            else {
                take line($depth, "<$tag$att/>")
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
        take line($depth, "<!-- tag <{.name}> ({.WHAT.^name})) -->")
            given $node.value;
    }
    if $!render {
        with $node.value.?Stm {
            warn "can't handle marked content streams yet";
        }
        else {
            take line($depth, trim(self!marked-content($node, :$depth)));
        }
    }
}

multi method stream-xml(PDF::Tags::Text $_, :$depth!) {
    take line($depth, html-escape(.Str));
}

method !marked-content(PDF::Tags::Mark $node, :$depth!) is default {
    # join text strings. discard this, and child marked content tags for now
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
    my $tag := $node.tag;
    my $atts := atts-str($node.attributes);
    my $omit-tag = $tag ~~ $_ with $!omit;
    $omit-tag
        ?? $text
        !! ($text ?? "<$tag$atts>"~$text~"</$tag>" !! "<$tag$atts/>");
}

=begin pod
=end pod
