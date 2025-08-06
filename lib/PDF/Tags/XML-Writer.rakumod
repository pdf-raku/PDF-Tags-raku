#| XML Serializer for tagged PDF structural items
unit class PDF::Tags::XML-Writer;

use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Node;
use PDF::Tags::ObjRef;
use PDF::Tags::Node::Parent;
use PDF::Tags::Node::Root;
use PDF::Tags::Mark;
use PDF::Tags::Tag;
use PDF::Tags::Text;
use PDF::Tags::XPath;
use PDF::Class::StructItem;
use PDF::Content::Tag :Tags;
use PDF::COS;
use PDF::COS::Null;

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
has Bool $.artifacts = False;
has Bool $!got-nl = True;
has Bool $!feed;
has Bool $!snug = True;
has Int  $!n = 0;
has Str %!role-map;

multi submethod TWEAK(PDF::Tags :$root) {
    with $root {
        $!root-tag //= 'DocumentFragment' if .elems != 1;
        if $!roles && .role-map {
            %!role-map = .role-map.grep: {.key ~~ /^<ident>$/};
        }
    }
}

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
    CATCH { default { warn $_ } }
    my $n0 = $!n;
    &action();
    $!n == $n0;
}

method !line(|c) { $!feed = True; self!chunk(|c); $!feed = True; }
method !frag(|c) { $*inline ?? self!chunk(|c) !! self!line(|c) }

sub xml-escape(Str:D $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
}
multi sub str-escape(@a) { @a.map(&str-escape).join: ' '; }
multi sub str-escape(Any:U) { 'null' }
multi sub str-escape(PDF::COS::Null) { 'null' }
multi sub str-escape(Str $_) {
    .&xml-escape.trans: /\"/ => '&quote;';
}
multi sub str-escape(Pair $_) { .value.&str-escape }
multi sub str-escape(Bool $_) { .so ?? 'true' !! 'false' }
multi sub str-escape(Numeric $_) { .Str.&str-escape }
multi sub str-escape(PDF::COS $_ where .is-indirect) {
    '%d %d R'.sprintf: .obj-num, .gen-num;
}
multi sub str-escape($_) { .Str.&str-escape }

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
    self!line('<?pdf-role-map' ~ %!role-map.&atts-str ~ ' ?>')
        if %!role-map;
    self!line('<' ~ $_ ~ '>', $depth++)
        with $!root-tag;

    if .elems {
        self.stream-xml($_, :$depth) for .kids;
    }

    self!line('</' ~ $_ ~ '>', --$depth)
        with $!root-tag;
}

method !actual-text($node) {
    my Str $actual-text;
    if $node ~~ PDF::Tags::Node::Parent|PDF::Tags::Text {
        $actual-text = $node.ActualText;
        if $!omit {
            without $actual-text {
                # flatten child elements if they are all omitted and have actual text
                $_ = $node.kids.map({ .ActualText }).join
                    unless $node.kids.first: {!(.name ~~ $!omit && .?ActualText.defined)};
            }
        }
    }

    $actual-text;
}

multi sub inlined-elem(Str $name, %atts) {
    with %atts<Placement> {
        # From PDF 2.0 Table 387 Standard layout attributes common to all standard structure types,
        # regarding 'Placement':
        #     "When applied to an ILSE, any value except Inline shall cause the
        #      element to be treated as a BLSE instead"
        $_ eq 'Inline'
    }
    else {
        InlineElemTags($name).so;
    }
}

sub find-href($node) {
    my constant &object-refs = PDF::Tags::XPath.compile: 'descendant::object()';
    my Str $href;
    for $node.find(&object-refs) {
        $href ||= .value with .ast;
    }
    $href;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0) {
    if $!debug {
        self!chunk("<!-- struct elem {.obj-num} {.gen-num} R -->", $depth)
            given $node.cos;
    }
    my $name = $node.name;
    my $role = $node.role if $!roles;
    if $role {
        if %!role-map{$role} {
            $name = $role
        }
        else {
            $role = Nil;
        }
    }

    my $actual-text = self!actual-text($node);
    my %attributes;
    my $att = do if $!atts {
        %attributes = $node.attributes;
        if $role {
            %attributes<role>:delete;
        }
        %attributes<Lang> = $_ with $node.Lang;

        if $name eq 'Link' {
            %attributes<href> = $_ with $node.&find-href;
        }
        %attributes.&atts-str;
    } // '';
    my $*inline = inlined-elem($name, %attributes);
    return if $name eq 'Artifact' && !$!artifacts;
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
            
            given .&xml-escape {
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

multi method stream-xml(PDF::Tags::ObjRef $node, :$depth!) {
    if $!debug {
        self!line("<!-- OBJR {.cos.Obj.obj-num} {.cos.Obj.gen-num} R -->", $depth)
            given $node;
    }
    if $!fields {
        given $node.value {
            when PDF::Field { self!chunk($_, $depth) with .value }
        }
    }
}

multi method stream-xml(PDF::Tags::Mark $node, :$depth!) {
    if self!tagged-content($node, :$depth) -> $text {
        self!chunk($text, $depth);
    }
}

multi method stream-xml(PDF::Tags::Text $node, :$depth!) {
    if $node.Str -> $text {
        self!chunk($text.&xml-escape, $depth);
    }
}

method !tagged-content(PDF::Tags::Tag $node, :$depth!) {
    my $name := $node.name;
    return '' if $name eq 'Artifact' && !$!artifacts;
    my Str $text = .&xml-escape() with $node.actual-text;
    $text //= do {
        my @text = $node.kids.map: {
            when PDF::Tags::Tag {
                self!tagged-content($_, :$depth);
            }
            when PDF::Tags::Text { .Str.&xml-escape }
            default { die "unhandled tagged content: {.WHAT.raku}"; }
        }
        @text.join;
    }
    my $tag-atts = '';
    if ($!atts) {
        $tag-atts  = .&atts-str() with $node.attributes;
    }
    my $omit-tag = ! $!marks;
    $omit-tag ||= $name ~~ $_ with $!omit;

    if $omit-tag && $tag-atts && !($!omit ~~ 'Span') {
        $name = 'Span';
        $omit-tag = False;
    }
    $text = '<' ~ $name ~ $tag-atts ~ ($text ?? "\>$text\</$name\>" !! '/>')
        unless $omit-tag;

    if $!marks && $node.isa(PDF::Tags::Mark) && !($!omit ~~ 'Mark') {
        my %atts = :MCID($node.mcid);
        if $!debug {
            %atts<Pg> = "{.obj-num} {.gen-num} R"
                with $node.value.canvas;
        }
        $text = '<Mark%s'.sprintf(%atts.&atts-str) ~ ($text ?? "\>$text\</Mark\>" !! '/>');
    }
    $text
}

=begin pod

=head2 Synopsis

    use PDF::Class;
    use PDF::Tags::Reader;
    use PDF::Tags::XML-Writer;
    my PDF::Class $pdf .= open: "t/write-tags.pdf";
    my PDF::Tags::Reader $tags .= read: :$pdf;
    my PDF::Tags::XML-Writer $xml-writer .= new: :debug;
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
