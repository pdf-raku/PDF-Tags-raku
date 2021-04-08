#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Catalog;
use PDF::StructTreeRoot;
use PDF::Tags::XML-Writer;
use PDF::Tags::Node :TagName;
use PDF::IO;

subset Number of Int where * > 0;

sub MAIN(Str $infile,               #= input PDF
	 Str     :$password = '',   #= password for the input PDF, if encrypted
         Number  :$max-depth = 16,  #= depth to ascend/descend struct tree
         Bool    :$atts = True,     #= include attributes in tags
         Bool    :$debug,           #= write extra debugging information
         Bool    :$graphics,        #= dump graphics state
         Bool    :$marks = $graphics,           #= descend into marked content
         Bool    :$strict = True,   #= warn about unknown tags, etc
         Bool    :$style = True,    #= include stylesheet
         Str     :$select,          #= XPath of twigs to include (relative to root)
         TagName :$omit,            #= Tags to omit from output
         TagName :$root-tag,        #= Outer root tag name
        ) {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Tags $dom .= read: :$pdf, :$strict, :$graphics, :$marks;
    my PDF::Tags::XML-Writer $xml .= new: :$max-depth, :$atts, :$debug, :$omit, :$style, :$root-tag, :$marks;

    my PDF::Tags::Node @nodes = do with $select {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    my UInt $depth = 0;

    with $root-tag {
        unless @nodes[0] ~~ PDF::Tags:D {
            say '<' ~ $_ ~ '>';
            $depth++;
        }
    }

    $xml.say($*OUT, $_, :$depth) for @nodes;

    say '</' ~ $root-tag ~ '>' if $depth;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --select=XPath      nodes to be included
   --omit=tag-name     nodes to be excluded
   --root-tag=tag-name define outer root tag
   --marks             decend into marked content
   --debug             add debugging to output
   --/atts             omit attributes in tags
   --/strict           suppress warnings
   --/style            omit root stylesheet link

=head1 DESCRIPTION

Dumps structure elements from a tagged PDF.

Produces tagged output in an XML format.

Only some PDF files contain tagged PDF. pdf-info.raku can be
used to check this:

    % pdf-info.raku my-doc.pdf | grep Tagged:
    Tagged:     yes

=head1 DEPENDENCIES

This script requires the freetype6 native library and the PDF::Font::Loader
Raku module to be installed on your system.

=head1 BUGS AND LIMITATIONS

=item 

=head1 TODO

=item processing of links and fields

=end pod
