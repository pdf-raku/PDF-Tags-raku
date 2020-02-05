unit class PDF::Tags::XML;

use PDF::Annot;
use PDF::Tags :StructNode;
use PDF::Tags::Elem;
use PDF::Tags::Item;
use PDF::Tags::ObjRef;
use PDF::Tags::Root;
use PDF::Tags::Tag;
use PDF::Tags::Text;

has UInt $.max-depth = 16;
has Bool $.render = True;
has Bool $.atts = True;
has Bool $.debug = False;
has Bool $.skip = False;

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

method !skip($tag) { $!skip && $tag eq 'Span' }

method Str(PDF::Tags::Item $item) {
    my @chunks = gather { self.take-xml($item) };
    @chunks.join;
}

method print(IO::Handle $fh, PDF::Tags::Item $item) {
    for gather self.take-xml($item) {
        $fh.print($_);
    }
}
method say(IO::Handle $fh, PDF::Tags::Item $item) {
    self.print($fh, $item);
    $fh.say: '';
}

multi method take-xml(PDF::Tags::Root $_, :$depth = 0) {
    self.take-xml($_, :$depth) for .kids;
}

multi method take-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
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

    if $depth >= $!max-depth {
        take line($depth, "<$tag$att/> <!-- depth exceeded, see {$node.value.obj-num} {$node.value.gen-num} R -->");
    }
    else {
        with $node.actual-text {
            take line($depth, '<!-- actual text -->')
                if $!debug;
            given trim($_) {
                take $_ eq ''
                    ?? line($depth, "<$tag$att/>")
                    !! line($depth, self!skip($tag) ?? $_ !! "<$tag$att>{html-escape($_) }</$tag>");
            }
        }
        else {
            my $elems = $node.elems;
            if $elems {
                take line($depth++, "<$tag$att>")
                    unless self!skip($tag);
        
                for 0 ..^ $elems {
                    self.take-xml($node.kids[$_], :$depth);
                }

                take line(--$depth, "</$tag>")
                    unless self!skip($tag);
            }
            else {
                take line($depth, "<$tag$att/>")
                    unless self!skip($tag);
            }
        }
    }
}

multi method take-xml(PDF::Tags::ObjRef $_, :$depth!) {
    take line($depth, "<!-- OBJR {.object.obj-num} {.object.gen-num} R -->")
        if $!debug;
     take self.take-object(.object, :$depth);
}

multi method take-xml(PDF::Tags::Tag $node, :$depth!) {
    if $!debug {
        take line($depth, "<!-- tag <{.name}> ({.WHAT.^name})) -->")
            given $node.value;
    }
    if $!render {
        with $node.value.?Stm {
            warn "can't handle marked content streams yet";
        }
        else {
            take line($depth, self!tag-content($node, :$depth));
        }
    }
}

multi method take-xml(PDF::Tags::Text $_, :$depth!) {
    take line($depth, html-escape(.Str));
}

method !tag-content(PDF::Tags::Tag $node, :$depth!) is default {
    # join text strings. discard this, and child marked content tags for now
    my $text = $node.actual-text // do {
        my @text = $node.kids.map: {
            when PDF::Tags::Tag {
                my $text = trim(self!tag-content($_, :$depth));
            }
            when PDF::Tags::Text { html-escape(.Str) }
            default { die "unhandled tagged content: {.WHAT.perl}"; }
        }
        @text.join;
    }
    my $tag = $node.tag;
    my $atts = atts-str($node.attributes);
    $!skip
    && ($node.tag eq 'Document'
        || self!skip($tag)
        || $node.value ~~ PDF::Content::Tag::Marked && $node.tag eq $node.parent.tag)
        ?? $text
        !! ($text ?? "<$tag$atts>"~$text~"</$tag>" !! "<$tag$atts/>")
}

multi method take-object(PDF::Field $_, :$depth!) {
    warn "todo: dump field obj" if $!debug; '';
}

multi method take-object(PDF::Annot $_, :$depth!) {
    warn "todo: dump annot obj: " ~ .perl if $!debug;
}
