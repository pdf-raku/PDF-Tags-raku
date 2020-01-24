#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Annot;
use PDF::Catalog;
use PDF::StructTreeRoot;

use PDF::DOM :StructNode;
use PDF::DOM::Elem;
use PDF::DOM::Item;
use PDF::DOM::ObjRef;
use PDF::DOM::Root;
use PDF::DOM::Tag;
use PDF::DOM::Text;
use PDF::DOM::XPath;

use PDF::Content::Tag;
use PDF::IO;

constant StandardTag = PDF::StructTreeRoot::StandardStructureType;
subset Number of Int where { !.defined || $_ > 0 };

sub html-escape(Str $_) {
    .trans:
        /\&/ => '&amp;',
        /\</ => '&lt;',
        /\>/ => '&gt;',
}

sub MAIN(Str $infile,              #= input PDF
	 Str :$password = '',      #= password for the input PDF, if encrypted
         Number :$*max-depth = 16, #= depth to ascend/descend struct tree
         Str    :$path,            #= XPath expression of nodes to dump 
         Bool   :$*render = True,  #= include rendered content
         Bool   :$*atts = True,    #= include attributes in tags
         Bool   :$*debug,          #= write extra debugging information
         Bool   :$*skip,           #= skip some repeated or unimportant tags
         Bool   :$*strict = True;  #= warn about unknown tags, etc
    ) {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Catalog $catalog = $pdf.catalog;
    my PDF::StructTreeRoot:D $root =  $pdf.catalog.StructTreeRoot
        // die "document does not contain marked content: $infile";

    my PDF::DOM $dom .= new: :$root, :$*render, :$*strict;

    my @nodes = do with $path {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    dump-node($_, :depth(0)) for @nodes;
}

sub pad(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s }

multi sub dump-node(PDF::DOM::Root $_, :$depth = 0) {
    dump-node($_, :$depth) for .kids;
}

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{.value}\"" }).join;
}

sub skip($tag) { $*skip && $tag eq 'Span' }

multi sub dump-node(PDF::DOM::Elem $node, UInt :$depth is copy = 0) {
    if $*debug {
        say pad($depth, "<!-- elem {.obj-num} {.gen-num} R ({.WHAT.^name})) -->")
            given $node.item;
    }
    my $tag = $node.tag;
    my $att = do if $*atts {
        my %attributes = $node.attributes;
        %attributes<O>:delete;
        atts-str(%attributes);
    }
    else {
        $tag = $_
            with $node.dom.role-map{$tag};
        ''
    }


    if $depth >= $*max-depth {
        say pad($depth, "<$tag$att/> <!-- depth exceeded, see {$node.item.obj-num} {$node..item.gen-num} R -->");
    }
    else {
        with $node.actual-text {
            say pad($depth, '<!-- actual text -->')
                if $*debug;
            given trim($_) {
                if $_ eq '' {
                    say pad($depth, "<$tag$att/>")
                        unless skip($tag);
                }
                else {
                    say pad($depth, skip($tag) ?? $_ !! "<$tag$att>{html-escape($_) }</$tag>")
                }
            }
        }
        else {
            my $elems = $node.elems;
            if $elems {
                say pad($depth++, "<$tag$att>")
                    unless skip($tag);
        
                for 0 ..^ $elems {
                    dump-node($node.kids[$_], :$depth);
                }

                say pad(--$depth, "</$tag>")
                    unless skip($tag);
            }
            else {
                say pad($depth, "<$tag$att/>")
                    unless skip($tag);
            }
        }
    }
}

multi sub dump-node(PDF::DOM::ObjRef $_, :$depth!) {
    say pad($depth, "<!-- OBJR {.object.obj-num} {.object.gen-num} R -->")
        if $*debug;
    dump-object(.object, :$depth);
}

multi sub dump-node(PDF::DOM::Tag $node, :$depth!) {
    if $*debug {
        say pad($depth, "<!-- tag <{.name}> ({.WHAT.^name})) -->")
            given $node.item;
    }
    return unless $*render;
    with $node.item.?Stm {
        warn "can't handle marked content streams yet";
    }
    else {
        dump-tag($node, :$depth);
    }
}

multi sub dump-node(PDF::DOM::Text $_, :$depth!) {
    say pad($depth, .Str)
}

sub tag-content(PDF::DOM::Tag $node, :$depth!) is default {
    # join text strings. discard this, and child marked content tags for now
    my $text = $node.actual-text // do {
        my @text = $node.kids.map: {
            when PDF::DOM::Tag {
                my $text = trim(tag-content($_, :$depth));
            }
            when PDF::DOM::Text { html-escape(.Str) }
            default { die "unhandled tagged content: {.WHAT.perl}"; }
        }
        @text.join;
    }
    my $tag = $node.tag;
    my $atts = atts-str($node.attributes);
    ($*skip
     && ($node.tag eq 'Document'
         || skip($tag)
         || $node.item ~~ PDF::Content::Tag::Marked && $node.tag eq $node.parent.tag))
        ?? $text
        !! ($text ?? "<$tag$atts>"~$text~"</$tag>" !! "<$tag$atts/>");
}

sub dump-tag(PDF::DOM::Tag $tag, :$depth!) is default {
    say pad($depth, tag-content($tag, :$depth));
}

multi sub dump-object(PDF::Field $_, :$depth!) {
    warn "todo: dump field obj" if $*debug;
}

multi sub dump-object(PDF::Annot $_, :$depth!) {
    warn "todo: dump annot obj: " ~ .perl if $*debug;;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --path=XPath        dump selected node(s)
   --skip              skip some tags, including <Span> and empty </P>
   --/render           omit rendering (avoid finding content-level tags)
   --/atts             omit attributes in tags
   --/strict           suppress warnings

=head1 DESCRIPTION

Locates and dumps structure elements from a tagged PDF.

Produces raw tagged output in an XML/SGMLish format.

Only some PDF files contain tagged PDF. pdf-info.p6 can be
used to check this:

    % pdf-info.p6 my-doc.pdf | grep Tagged:
    Tagged:     yes

=head1 DEPENDENCIES

This script requires the freetype6 native library and the PDF::Font::Loader
Raku module to be installed on your system.

=head1 BUGS AND LIMITATIONS

=item 

=head1 TODO

=item processing of links and fields

=end pod
