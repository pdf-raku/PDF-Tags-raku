#| XML Serializer for tagged PDF structural items
unit class PDF::Tags::XML-Writer;

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
has Bool $.roles;
has Str  $.css = '<?xml-stylesheet type="text/css" href="https://pdf-raku.github.io/css/tagged-pdf.css"?>';
has Str  $.dtd = 'http://pdf-raku.github.io/dtd/tagged-pdf.dtd';
has Bool $.style = True;
has Bool $.debug = False;
has Bool $.marks;
has Bool $.fields = True;
has Bool $.valid = !$!marks && !$!roles;
has Str  $.omit;
has Str  $.root-tag;
has Bool $!got-nl = True;
has Bool $!feed;
has Bool $!snug = True;
has Int $!n = 0;

method !chunk(Str $s is copy, UInt $depth = 0) {
    if $s {
        $!n++;
        if $!feed || $!got-nl {
            take "\n" ~ ('  ' x $depth) unless $!snug--;
            $!feed = False;
        }
        if $*inline && $s {
            take $s
        }
        else {
            # defer output of final new-line - indentation may change
            $!got-nl = so($s ~~ s/\n$//);
            take $s.subst(/\n/, { "\n" ~ ( '  ' x $depth)}, :g);
        }
    }
}

method !no-output(&action --> Bool) {
    my $n0 = $!n;
    &action();
    $!n == $n0;
}

method !line(|c) { $!feed = True; self!chunk(|c); $!feed = True; }
method !frag(|c) { $*inline ?? self!chunk(|c) !! self!line(|c) }

sub xml-escape(Str $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
}
multi sub str-escape(@a) { @a.map(&str-escape).join: ' '; }
multi sub str-escape(Str $_) {
    xml-escape($_).trans: /\"/ => '&quote;';
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
    if $!dtd && $!valid {
        my $doctype = $!root-tag;
        $doctype //= .name with .kids.head;
        $doctype //= 'Document';
        self!frag: qq{<!DOCTYPE $doctype SYSTEM "$!dtd">};
    }
    self!line($!css) if $!style;
    $!root-tag //= 'DocumentFragment' if .elems != 1;

    self!line('<' ~ $_ ~ '>', $depth++)
        with $!root-tag;

    if .elems {
        self.stream-xml($_, :$depth) for .kids;
    }

    self!line('</' ~ $_ ~ '>', --$depth)
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
    InlineElemTags($t).so;
}

sub find-href($node) {
    use PDF::Annot::Link;
    use PDF::Action::URI;
    use PDF::Action::GoTo;
    use PDF::Action::GoToR;
    use PDF::Destination;

    my constant &object-refs = PDF::Tags::XPath.compile: 'descendant::object()';
    my Str $href;
    for $node.find(&object-refs) {
        given .value {
            when PDF::Annot::Link {
                my $l = $_;
                with $l<A> // $l<PA> {
                    when PDF::Action::URI {
                        $href = .URI;
                        last;
                    }
                    when PDF::Action::GoTo {
                        given .<D> {
                            when Str {
                                $href = '#' ~ $_;
                                last;
                            }
                        }
                    }
                    when PDF::Action::GoToR {
                        $href = 'file://' ~ (.UF // .F);
                        given .<D> {
                            when Str {
                                $href ~= '#' ~ $_;
                                last;
                            }
                        }
                    }
                    when PDF::Destination {
                        # Todo: work out page number from page reference
                    }
                    default {
                        warn "ignoring {.WHAT.raku}";
                    }
                }
                else {
                    with $l<Dest> {
                        when Str {
                            $href = '#' ~ $_;
                            last;
                        }
                        when PDF::Destination {
                            # Todo: work out page number from page reference
                        }
                        default {
                            warn "ignoring {.WHAT.raku}";
                        }
                    }
                }
            }
            default {
                warn "ignoring {.WHAT.raku}";
            }
        }
    }
    $href;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        self!chunk("<!-- elem {.obj-num} {.gen-num} R -->", $depth)
            given $node.cos;
    }
    my $name = $node.name;
    my $role = $node.role if $!roles;
    my $actual-text = self!actual-text($node);
    my $*inline = inlined-tag($name);
    my $att = do if $!atts {
        my %attributes = $node.attributes;
        if $role {
            %attributes<role>:delete;
        }
        if $!marks {
            %attributes<ActualText> = $_ with $actual-text;
        }
        %attributes<Lang> = $_ with $node.Lang;

        if $name eq 'Link' {
            %attributes<href> = $_ with find-href($node);
        }
        atts-str(%attributes);
    } // '';
    $name = $_ with $role;
    my $omit-tag = $name ~~ $_ with $!omit;

    if $depth >= $!max-depth {
        self!line("<$name$att/> <!-- depth exceeded, see {$node.cos.obj-num} {$node.cos.gen-num} R -->", $depth);
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
            
            given xml-escape($_) {
                my $frag = do {
                    when $omit-tag.so { $_ }
                    when .so { '<%s%s>%s</%s>'.sprintf($name, $att, $_, $name) }
                    default  { '<%s%s/>'.sprintf($name, $att); }
                }
                self!frag($frag, $depth);
            }
        }
        if $!marks || !$actual-text.defined {
            # descend
            my $elems = $node.elems;
            if $elems {
                self!frag("<$name$att>", $depth++)
                    unless $omit-tag;
                temp $!snug = self!no-output: {
                    for ^$elems {
                        my $kid = $node.kids[$_];
                        self.stream-xml($kid, :$depth);
                    }
                }
                self!frag("</$name>", --$depth)
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
    self!line("<!-- OBJR {.cos.Obj.obj-num} {.cos.Obj.gen-num} R -->", $depth)
        if $!debug;
    if $!fields {
        given .value {
            when PDF::Field { self!chunk($_, $depth) with .value }
        }
    }
}

multi method stream-xml(PDF::Tags::Mark $node, :$depth!) {
    if $!debug {
        self!line("<!-- mark MCID:{.mcid} Pg:{.canvas.obj-num} {.canvas.gen-num} R -->", $depth)
            given $node.value;
    }
    if self!marked-content($node, :$depth) -> $text {
        self!chunk($text, $depth);
    }
}

multi method stream-xml(PDF::Tags::Text $_, :$depth!) {
    if .Str -> $text {
        self!chunk(xml-escape($text), $depth);
    }
}

method !marked-content(PDF::Tags::Mark $node, :$depth!) {
    my $text = $node.actual-text // do {
        my @text = $node.kids.map: {
            when PDF::Tags::Mark {
                my $text = self!marked-content($_, :$depth);
            }
            when PDF::Tags::Text { xml-escape(.Str) }
            default { die "unhandled tagged content: {.WHAT.raku}"; }
        }
        @text.join;
    }
    my $name := $node.name;
    my $omit-tag = ! $!marks;
    $omit-tag ||= $name ~~ $_ with $!omit;
    if $omit-tag {
        if $!atts && !($!omit ~~ 'Span') {
            # try to retain content-level language tags
            my $Lang := .<Lang>
                with $node.attributes;
            if $Lang {
                $text = sprintf('<Span Lang="%s">%s</Span>', xml-escape($Lang), $text);
            }
        }
        $text;
    }
    else {
        my $atts-str := $!atts ?? atts-str($node.attributes) !! '';
        "\<$name$atts-str" ~ ($text ?? "\>$text\</$name\>" !! '/>');
    }
}

=begin pod

=head2 Synopsis

    use PDF::Class;
    use PDF::Tags::Reader;
    use PDF::Tags::XML-Writer;
    my PDF::Class $pdf .= open: "t/write-tags.pdf";
    my PDF::Tags::Reader $tags .= read: :$pdf;
    my PDF::Tags::XML-Writer $xml-writer .= new: :debug, :root-tag<Docs>;
    # atomic write
    say $xml-writer.Str($tags);
    # streamed write
    $xml-writer.say($*OUT, $tags);
    # do our own streaming
    for gather $xml-writer.stream-xml($tags) {
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
