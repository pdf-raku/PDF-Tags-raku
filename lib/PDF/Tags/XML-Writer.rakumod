#| XML Serializer for tagged PDF structural items
unit class PDF::Tags::XML-Writer;

use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Tags::Node :TagName;
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
use PDF::COS::DateString;
use PDF::COS::Null;

has UInt $.max-depth = 16;
has Bool $.atts = True;
has Bool $.roles;
has Bool $.class-names;
has Str  $.xsl;
has Str  $.css;
has Str  $.dtd = 'http://pdf-raku.github.io/dtd/tagged-pdf.dtd';
has Bool $.style = True;
has Bool $.debug = False;
has Bool $.marks;
has Bool $.fields = True;
has Bool $.valid = !$!marks && !$!roles;
has Str  $.omit;
has Str  $.root-tag;
has Bool $.artifacts = False;
has Int  $!block-count = 0;
has Str %!role-map;
has Hash $!class-map;
has Any:D %.info;
has $!left-trim;
has $!right-trim;

submethod TWEAK(PDF::Tags :$root) {
    with $root {
        $!root-tag //= 'DocumentFragment' if .elems != 1;
        if $!roles && .role-map {
            %!role-map = .role-map.grep: {.key ~~ TagName};
        }
        if $!class-names && .class-map {
            $!class-map := .class-map;
        }
        %!info ,= .info;
    }

    # CSS is applied after XSL
    $!css //= "https://pdf-raku.github.io/css/tagged-pdf.css"
        unless $!xsl;
}

sub pad($depth) {
    "\n" ~ ( '  ' x $depth);
}

method !chunk(Str:D $s is copy) {
    take $s;
}

method !line($str, $indent=0) {
    take $indent.&pad if $indent;
    self!chunk($str);
    take "\n";
}

sub xml-escape(Str:D $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
}
multi sub str-escape(@a) { @a.map(&str-escape).join: ' '; }
multi sub str-escape(Any:U) { 'null' }
multi sub str-escape(PDF::COS::Null) { 'null' }
multi sub str-escape(PDF::COS::DateString $ds) {
    my $timezone = $ds.timezone;
    my $posix    = $ds.posix;
    my DateTime $dt .= new: $posix, :$timezone;
    $dt.gist;
}
multi sub str-escape(Str $_) {
    .&xml-escape.trans: /\"/ => '&quote;';
}
multi sub str-escape(Pair $_) { .value.&str-escape }
multi sub str-escape(Bool $_) { .so ?? 'true' !! 'false' }
multi sub str-escape(Numeric $_) { .Str }
multi sub str-escape(PDF::COS $_ where .is-indirect) {
    '%d %d R'.sprintf: .obj-num, .gen-num;
}
multi sub str-escape($_) { .Str.&str-escape }

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{.value.&str-escape}\"" }).join;
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
method say(IO::Handle $fh, |c) {
    self.print($fh, |c);
    $fh.say: '';
}

multi method stream-xml(PDF::Tags::Node::Root $_, UInt :$depth is copy = 0) {
    self!line('<?xml version="1.0" encoding="UTF-8"?>');
    if $!dtd && $!valid {
        my $doctype = $!root-tag;
        $doctype //= .name with .kids.head;
        $doctype //= 'Document';
        self!line: qq{<!DOCTYPE $doctype SYSTEM "$!dtd">};
    }
    if $!style {
        self!line: qq[<?xml-stylesheet type="text/xml" href="{.&str-escape}"?>] with $!xsl;
        self!line: qq[<?xml-stylesheet type="text/css" href="{.&str-escape}"?>] with $!css;
    }
    self!line('<?pdf-role-map' ~ %!role-map.&atts-str ~ '?>')
        if %!role-map;
    if $!class-names && $!class-map {
        self!line('<?pdf-class "' ~ .&str-escape() ~ '"' ~ $!class-map{$_}.Hash.&atts-str() ~ '?>')
            for $!class-map.keys.sort;
    }
    temp %!info;
    with $!root-tag {
        self!line('<' ~ $_ ~ %!info.&atts-str ~ '>');
        ++$depth;
        %!info = ();
    }

    if .elems {
        self.stream-xml($_, :$depth, :%!info) for .kids;
    }

    with $!root-tag {
        self!line('</' ~ $_ ~ '>');
        -- $depth;
    }
}

method !trim($s is copy) {
    $s ~~ s/^\n// if $!left-trim--;
    $s ~~ s/\n$// if $!right-trim--;
    $s
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

sub inlined-elem($name, %atts) {
    with %atts<Placement> {
        # From PDF 2.0 Table 387 Standard layout attributes common to all standard structure types,
        # regarding 'Placement':
        #     "When applied to an ILSE, any value except Inline shall cause the
        #      element to be treated as a BLSE instead"
        $_ eq 'Inline'
    }
    else {
        $name eq 'Mark' || InlineElemTags($name).so;
    }
}

sub sanitize-id(Str:D $id) {
    $id.subst(rx:i/<- [a..z 0..9 _ : . -]>/, '_', :g);
}

sub find-href($node) {
    my constant &object-refs = PDF::Tags::XPath.compile: 'descendant::object()';
    my Str $href;
    for $node.find(&object-refs) {
        $href ||= .value with .ast;
    }
    ($href && $href.starts-with('#'))
        ?? '#' ~ $href.substr(1).&sanitize-id
        !! $href;
}

multi method stream-xml(PDF::Tags::Elem $node, UInt :$depth is copy = 0, :%info) {
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

    my $actual-text = self!trim($_) with self!actual-text($node);
    my $omit-tag = $name ~~ $_ with $!omit;
    my %attributes;
    my $att = do if $!atts {
        %attributes = $node.attributes(:$!class-names);
        %attributes ,= %info;
        if $role {
            %attributes<role>:delete;
        }
        %attributes<Lang> = $_ with $node.Lang;

        if $name eq 'Link' {
            %attributes<href> = $_ with $node.&find-href;
        }

        with $node.id {
            if $omit-tag {
                # Omit the tag, but preserve the ID, to avoid broken internal links
                %attributes = ();
                $name = 'Span';
                $omit-tag = False;
            }
            %attributes<id> //= .&sanitize-id;
        }

        %attributes.&atts-str;
    } // '';

    return if $name eq 'Artifact' && !$!artifacts;

    if $depth >= $!max-depth {
        self!line("<$name$att/> <!-- depth exceeded, see {$node.cos.obj-num} {$node.cos.gen-num} R -->", $depth);
    }
    else {
        my $is-block = ! ($omit-tag || $name.&inlined-elem(%attributes));
        my $block-id;
        if $is-block {
            $block-id = ++$!block-count;
            take $depth.&pad if $depth;
        }

        with $actual-text {
            if $!debug {
                if $!marks {
                    self!line("<!-- actual text: {.raku} -->", $depth)
                }
                else {
                    self!line('<!-- actual text -->', $depth);
                }
            }
            
            given self!trim($_).&xml-escape {
                my $frag = do {
                    when $omit-tag.so { $_ }
                    when .so { '<%s%s>%s</%s>'.sprintf($name, $att, $_, $name) }
                    default  { '<%s%s/>'.sprintf($name, $att); }
                }
                self!chunk($frag);
            }
        }
        if $!marks || !$actual-text.defined {
            # descend
            my $elems = $node.elems;
            if $elems {
                $depth++ if $is-block;

                self!chunk("<$name$att>") unless $omit-tag;

                for ^$elems {
                    $!left-trim = $_ == 0 if $is-block;
                    $!right-trim = $_ == $elems -1 if $is-block;
                    my $kid = $node.kids[$_];
                    self.stream-xml($kid, :$depth);
                }

                $depth-- if $is-block;
                take $depth.&pad
                   if $is-block && $block-id != $!block-count;

                self!chunk("</$name>") unless $omit-tag;
            }
            else {
                self!chunk("<$name$att/>")
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

multi method stream-xml(PDF::Tags::Mark $node) {
    if self!tagged-content($node) -> $text {
        self!chunk: self!trim($text);
    }
}

multi method stream-xml(PDF::Tags::Text $node) {
    if $node.Str -> $text {
        self!chunk: self!trim($text).&xml-escape;
    }
}

method !tagged-content(PDF::Tags::Tag $node) {
    my $name := $node.name;
    return '' if $name eq 'Artifact' && !$!artifacts;
    my Str $text = self!trim($_).&xml-escape() with $node.actual-text;
    $text //= do {
        my @text = $node.kids.map: {
            when PDF::Tags::Tag {
                self!tagged-content($_);
            }
            when PDF::Tags::Text { self!trim(.Str).&xml-escape }
            default { die "unhandled tagged content: {.WHAT.raku}"; }
        }
        @text.join;
    }
    my $tag-atts = '';
    if $!atts {
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
        my %atts = :MCID($node.mcid) if $!atts || $!debug;
        with $node.Pg {
            %atts<Pg> = sprintf('%d %d R', .obj-num, .gen-num);
        }
        else {
            %atts<Stm> = sprintf('%d %d R', .obj-num, .gen-num)
                with $node.Stm;
        }
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

Calling `$node.xml(|c)`, is equivalent to: `PDF::Tags::XML-Writer.new(|c).Str($node)`.

=end pod
