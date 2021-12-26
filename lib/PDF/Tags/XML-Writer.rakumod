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
use PDF::Content::Tag :Tags;

has UInt $.max-depth = 16;
has Bool $.atts = True;
has $.css = '<?xml-stylesheet type="text/css" href="https://pdf-raku.github.io/css/tagged-pdf.css"?>';
has Bool $.style = True;
has Bool $.debug = False;
has Bool $.marks;
has Str  $.omit;
has Str  $.root-tag;
has $!got-nl = True;
has $!feed;

method !chunk(Str $s, UInt $depth = 0) {
    if $s {
        if $!feed || $!got-nl {
            take "\n" unless $!got-nl;
            take '  ' x $depth;
            $!feed = False;
        }
        $!got-nl = $s ~~ /\n$/;
        take $s;
    }
}

method !line(|c) { $!feed = True; self!chunk(|c); $!feed = True; }
method !frag(:$inline, |c) { $inline ?? self!chunk(|c) !! self!line(|c) }

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
    self!line('<?xml version="1.0" encoding="UTF-8"?>');
    self!line($!css) if $!style;

    self!line('<' ~ $_ ~ '>', $depth++)
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
    self!line(--$depth, '</' ~ $_ ~ '>', --$depth)
        with $!root-tag;
}

method !actual-text($node) {
    my $actual-text;
    if $node ~~ PDF::Tags::Node::Parent|PDF::Tags::Text {
        $actual-text = $node.ActualText;
        with $!omit {
            without $actual-text {
                # flatten child elements if they are all omitted and have actual text
                $_ = $node.kids.map({ .ActualText }).join
                    unless $node.kids.first: {!(.name ~~ $!omit && .?ActualText.defined)};
            }
        }
    }

    $actual-text;
}

multi sub inlined-tag(Str $t) {
    InlineElemTags($t);
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        self!chunk("<!-- elem {.obj-num} {.gen-num} R -->", $depth)
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
    my $inline = inlined-tag($name);

    if $depth >= $!max-depth {
        self!line("<$name> <!-- depth exceeded, see {$node.cos.obj-num} {$node.cos.gen-num} R -->", $depth);
    }
    else {
        with $actual-text {
            if $!debug {
                if $!marks {
                    self!line("<!-- actual text: {.raku} -->", $depth)
                }
                else {
                    self!line('<!-- actual text -->', $depth);
                }
            }
            
            given html-escape($_) {
                my $frag = do {
                    when $omit-tag.so { $_ }
                    when .so { '<%s%s>%s</%s>'.sprintf($name, $att, $_, $name) }
                    default  { '<%s%s/>'.sprintf($name, $att); }
                }
                self!frag($frag, $depth, :$inline);
            }
        }
        if $!marks || !$actual-text.defined {
            # descend
            my $elems = $node.elems;
            if $elems {
                self!frag("<$name$att>", $depth++, :$inline)
                    unless $omit-tag;
        
                for ^$elems {
                    my $kid = $node.kids[$_];
                    self.stream-xml($kid, :$depth);
                }

                self!frag("</$name>", --$depth, :$inline)
                     unless $omit-tag;
            }
            else {
                self!chunk("<$name$att/>", $depth)
                    unless $omit-tag;
            }
        }
    }
}

multi method stream-xml(PDF::Tags::ObjRef $_, :$depth!) {
    self!line("<!-- OBJR {.cos.obj-num} {.cos.gen-num} R -->", $depth)
        if $!debug;
}

multi method stream-xml(PDF::Tags::Mark $node, :$depth!) {
    if $!debug {
        self!line("<!-- mark MCID:{.mcid} Pg:{.canvas.obj-num} {.canvas.gen-num} R-->", $depth)
            given $node.value;
    }
    if self!marked-content($node, :$depth) -> $text {
        self!line($text, $depth);
    }
}

multi method stream-xml(PDF::Tags::Text $_, :$depth!) {
    if .Str -> $text {
        self!line(html-escape($text), $depth);
    }
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
