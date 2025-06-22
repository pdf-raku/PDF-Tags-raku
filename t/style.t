use Test;
plan 6;

use PDF::Tags;
use PDF::Tags::Elem;
use PDF::Class;
use PDF::Content::Tag :Tags;

my $styler = try {require ::('CSS::TagSet::TaggedPDF')};

if $! {
   skip-rest "CSS::TagSet::TaggedPDF is required for style tests";
   exit 0;
}

$styler .= new;

my PDF::Class $pdf .= new;
my PDF::Tags $tags .= create: :$pdf, :$styler;
my PDF::Tags::Elem $doc = $tags.Document;

like $doc.style.Str, rx/"display:block"/, "document style";

my $h1 = $doc.Header1;
like $h1.style.Str, rx/"display:block".* "bolder"/, "Header1 style";

my $h2 = $doc.Header2;
like $h2.style.Str, rx/"display:block;".*"bolder"/, "Header2 style";

my $span = $h2.Span;
like $h2.style.Str, rx/"display:block;".*"bolder"/, "Header2/Span style";

my $para = $doc.Paragraph;
like $para.style.Str, rx/"display:block;".*"margin"/, "Paragraph style";

my $code-para = $para.Code;
like $code-para.style.Str, rx/"mono"/, "Paragraph/Code style";
