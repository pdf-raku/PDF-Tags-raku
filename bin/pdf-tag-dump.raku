#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Catalog;
use PDF::StructTreeRoot;
use PDF::Tags::XML-Writer;
use PDF::Tags::Node;
use PDF::IO;

subset Number of Int where { !.defined || $_ > 0 };

sub MAIN(Str $infile,              #= input PDF
	 Str :$password = '',      #= password for the input PDF, if encrypted
         Number :$max-depth = 16,  #= depth to ascend/descend struct tree
         Bool   :$atts = True,     #= include attributes in tags
         Bool   :$debug,           #= write extra debugging information
         Bool   :$marks,           #= show raw markws content
         Bool   :$strict = True,   #= warn about unknown tags, etc
         Bool   :$style = True,    #= include stylesheet
         Str    :$select,          #= XPath of twigs to include (relative to root)
         Str    :$omit,            #= Tags to omit from output
        ) {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Tags $tags .= read: :$pdf, :$strict, :$marks;
    my PDF::Tags::XML-Writer $xml .= new: :$max-depth, :$atts, :$debug, :$omit, :$style;

    my PDF::Tags::Node @nodes = do with $select {
        $tags.find($_);
    }
    else {
        $tags.root;
    }

    $xml.say($*OUT, $_) for @nodes;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --select=XPath      nodes to be included
   --omit=tag-name     nodes to be excluded
   --marks             dump content markers
   --debug             adding debugging to output
   --marks             show raw marked content
   --/atts             omit attributes in tags
   --/strict           suppress warnings
   --/style            omit stylesheet link

=head1 DESCRIPTION

Locates and dumps structure elements from a tagged PDF.

Produces raw tagged output in an XML/SGMLish format.

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
