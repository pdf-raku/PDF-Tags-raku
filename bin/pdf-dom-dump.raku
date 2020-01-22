#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Annot;
use PDF::Catalog;
use PDF::MCR;
use PDF::OBJR;
use PDF::Page;
use PDF::StructTreeRoot;
use PDF::StructElem :StructElemChild;
use PDF::DOM :StructNode;

use PDF::DOM::Elem;
use PDF::DOM::ObjRef;
use PDF::DOM::Root;
use PDF::DOM::Tag;
use PDF::DOM::XPath;

use PDF::Content;
use PDF::Content::Graphics;
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

    my PDF::DOM $dom .= new: :$root, :$*render;

    my @nodes = do with $path {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    dump-node($_) for @nodes;
}

sub pad(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s }

multi sub dump-node(PDF::DOM::Root $_, :$depth = 0) {
    dump-node($_, :$depth) for .kids;
}

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{.value}\"" }).join;
}

multi sub dump-node(PDF::DOM::Elem $node, UInt :$depth is copy = 0) {
    if $*debug {
        say pad($depth, "<!-- struct elem {.obj-num} {.gen-num} R ({.WHAT.^name})) -->")
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
    $depth++;

    if $depth >= $*max-depth {
        say pad($depth, "<$tag$att/> <!-- depth exceeded, see {.item.obj-num} {.item.gen-num} R -->");
    }
    else {
        with $node.item.ActualText {
            say pad($depth, '<!-- actual text -->')
                if $*debug;
            given trim($_) {
                if $_ eq '' {
                    say pad($depth, "<$tag$att/>")
                        unless $tag eq 'Span';
                }
                else {
                    say pad($depth, $tag eq 'Span' ?? $_ !! "<$tag$att>{html-escape($_) }</$tag>")
                }
            }
        }
        else {
            with $node.elems -> $elems {
                say pad($depth, "<$tag$att>")
                    unless $tag eq 'Span';
        
                for 0 ..^ $elems {
                    dump-node($node.kids[$_], :$depth);
                }

                say pad($depth, "</$tag>")
                    unless $tag eq 'Span';
            }
            else {
                say pad($depth, "<$tag$att/>")
                    unless $tag eq 'Span';
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
    return unless $*render;
    with $node.item.?Stm {
        warn "can't handle marked content streams yet";
    }
    else {
        with $node.item {
            dump-tag($node.item, :$depth);
        }
        else {
            warn "unable to resolve marked content {$node.item.mcid}";
        }
    }
}

multi sub dump-node($_, :$tags, :$depth) is default {
    die "unknown struct elem of type {.WHAT.^name}";
    say pad($depth, .perl);
}

sub tag-text(PDF::Content::Tag $tag, :$depth!) is default {
    # join text strings. discard this, and child marked content tags for now
    my @text = $tag.children.map: {
        when PDF::Content::Tag {
            my $text = trim(tag-text($_, :$depth));
            .name eq 'Document'
            ?? $text
            !! ($text ?? "<{.name}>" ~ $text ~ "</{.name}>" !! "</{.name}>");
        }
        when Str { html-escape($_) }
        default { '???' }
    }
    @text.join;
}

sub dump-tag(PDF::Content::Tag $tag, :$depth!) is default {
    say pad($depth, tag-text($tag, :$depth));
}

multi sub dump-object(PDF::Field $_, :$tags is copy, :$depth!) {
    warn "todo: dump field obj" if $*debug;
}

multi sub dump-object(PDF::Annot $_, :$tags is copy, :$depth!) {
    warn "todo: dump annot obj: " ~ .perl if $*debug;;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --path=XPath        dump selected node(s)
   --/render           omit rendering (avoid finding content-level tags)
   --/atts             ommit attributes in tags

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
