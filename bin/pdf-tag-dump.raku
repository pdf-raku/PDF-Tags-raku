#!/usr/bin/env perl6
use v6;

use PDF::Class;
use PDF::Catalog;
use PDF::StructTreeRoot;
use PDF::Tags::XML;
use PDF::IO;

subset Number of Int where { !.defined || $_ > 0 };

sub MAIN(Str $infile,              #= input PDF
	 Str :$password = '',      #= password for the input PDF, if encrypted
         Number :$max-depth = 16,  #= depth to ascend/descend struct tree
         Bool   :$render = True,   #= include rendered content
         Bool   :$atts = True,     #= include attributes in tags
         Bool   :$debug,           #= write extra debugging information
         Bool   :$marks,           #= also include content stream tags
         Bool   :$strict = True;   #= warn about unknown tags, etc
         Str    :$include,         #= XPath of twigs to include (relative to root)
         Str    :$omit,            #= Tags to omit from output
        ) {

    my PDF::IO $input .= coerce(
       $infile eq '-'
           ?? $*IN.slurp-rest( :bin ) # sequential access
           !! $infile.IO              # random access
    );

    my PDF::Class $pdf .= open( $input, :$password );
    my PDF::Catalog $catalog = $pdf.catalog;
    my PDF::StructTreeRoot:D $value =  $pdf.catalog.StructTreeRoot
        // die "PDF document does not contain marked content: $infile";

    my PDF::Tags $dom .= new: :$value, :$render, :$strict, :$marks, :root(PDF::Tags);
    my PDF::Tags::XML $xml .= new: :$max-depth, :$render, :$atts, :$debug, :$omit;

    my @nodes = do with $include {
        $dom.find($_);
    }
    else {
        $dom.root;
    }

    $xml.say($*OUT, $_) for @nodes;
}

=begin pod

=head1 SYNOPSIS

pdf-dom-dump.raku [options] file.pdf

Options:
   --password          password for an encrypted PDF
   --max-depth=n       maximum tag-depth to descend
   --xpath=expr        dump selected node(s)
   --marks             dump content markersd
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
