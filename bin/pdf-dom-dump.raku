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
use PDF::DOM::XPath;

use PDF::Content;
use PDF::Content::Graphics;
use PDF::IO;

constant StandardTag = PDF::StructTreeRoot::StandardStructureType;
subset Number of Int where { !.defined || $_ > 0 };


my PDF::DOM $*dom;

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
         UInt   :$obj-num,         #= Direct select by object number
         UInt   :$gen-num = 0,     #= Direct select by generation number
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

    my PDF::DOM $*dom .= new: :$root, :$*render;

    my $start = $obj-num
    ?? PDF::COS.coerce( $pdf.reader.ind-obj($obj-num, $gen-num).object,
                        PDF::StructElem)
    !! $root;

    my @nodes = do with $path {
        PDF::DOM::XPath.find($root, $_);
    }
    else {
        $start;
    }
    warn :@nodes.perl;

    dump-struct($_) for @nodes;
}

sub pad(UInt $depth, Str $s = '') { ('  ' x $depth) ~ $s }

multi sub dump-struct(PDF::StructTreeRoot $root, :$depth = 0) {
    with $root.K -> $k {
        my $elems = $k ~~ List ?? $k.elems !! 1;
        for 0 ..^ $elems {
            my StructElemChild $c = $k[$_];
            dump-struct($c, :$depth);
        }
    }
}

sub atts-str(%atts) {
    %atts.pairs.sort.map({ " {.key}=\"{.value}\"" }).join;
}

sub attributes($item) {
                    my %attributes;

                    for $item.attribute-dicts -> $atts {
                        %attributes{$_} = $atts{$_}
                            for $atts.keys
                    }

                    unless %attributes {
                        for $item.class-map-keys {
                            with $*dom.class-map{$_} -> $class {
                                %attributes{$_} = $class{$_}
                                    for $class.keys
                            }
                        }
                    }
                    %attributes;
}

multi sub dump-struct(PDF::StructElem $elem, :$tags is copy = %(), :$depth is copy = 0) {
    say pad($depth, "<!-- struct elem {$elem.obj-num} {$elem.gen-num} R ({$elem.WHAT.^name})) -->")
        if $*debug;
    $tags = $*dom.graphics-tags($_) with $elem.Pg;
    my $tag = $elem.tag;
    my $att = do if $*atts {
        my %attributes = attributes($elem);
        with $*dom.role-map{$tag} {
            %attributes<class> //= $tag;
            $tag = $_;
        }
        %attributes<O>:delete;
        atts-str(%attributes);
    }
    else {
        $tag = $_
            with $*dom.role-map{$tag};
        ''
    }
    $depth++;

    if $depth >= $*max-depth {
        say pad($depth, "<$tag$att/> <!-- depth exceeded, see {$elem.obj-num} {$elem.gen-num} R -->");
    }
    else {
        with $elem.ActualText {
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
            with $elem.K -> $k {
                my $elems = $k ~~ List ?? $k.elems !! 1;
                say pad($depth, "<$tag$att>")
                    unless $tag eq 'Span';
        
                for 0 ..^ $elems {
                    my StructElemChild $c = $k[$_];
                    dump-struct($c, :$tags, :$depth);
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

multi sub dump-struct(PDF::OBJR $_, :$tags is copy, :$depth!) {
    say pad($depth, "<!-- OBJR {.Obj.obj-num} {.Obj.gen-num} R -->")
        if $*debug;
    $tags = $*dom.graphics-tags($_) with .Pg;
    dump-struct($_, :$tags, :$depth) with .Obj;
}

multi sub dump-struct(UInt $mcid, :$tags is copy, :$depth!) {
    say pad($depth, "<!-- mcid $mcid -->")
        if $*debug;
    return unless $*render;
    with $tags{$mcid} -> $tag {
        dump-tag($tag, :$depth);
    }
    else {
        warn "unable to resolve marked content $mcid";
    }
}

multi sub dump-struct(PDF::MCR $_, :$tags is copy, :$depth!) {
    return unless $*render;
    say pad($depth, "<!-- MCR {.MCID} -->")
        if $*debug;
    $tags = $*dom.graphics-tags($_) with .Pg;
    my UInt $mcid := .MCID;
    with .Stm {
        warn "can't handle marked content streams yet";
    }
    else {
        with $tags{$mcid} -> $tag {
            dump-tag($tag, :$depth);
        }
        else {
            warn "unable to resolve marked content $mcid";
        }
    }
}

multi sub dump-struct(StructNode $_, |c) {
    dump-struct( $*dom.deref($_), |c);
}

multi sub dump-struct(PDF::Field $_, :$tags is copy, :$depth!) {
    warn "todo: dump field obj" if $*debug;
}

multi sub dump-struct(PDF::Annot $_, :$tags is copy, :$depth!) {
    warn "todo: dump annot obj: " ~ .perl if $*debug;;
}

multi sub dump-struct(List $a, :$depth!, |c) {
    say pad($depth, "<!-- struct list {$a.obj-num} {$a.gen-num} R -->")
        if $*debug;
    for $a.keys {
        dump-struct($_, :$depth, |c)
            with $a[$_];
    }
}

multi sub dump-struct($_, :$tags, :$depth) is default {
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

=begin pod

=head1 SYNOPSIS

pdf-struct-dump.p6 [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --page=p            dump page number p  
   --search-tag=name   tag to select
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

=item processing of annotations and links

=end pod
