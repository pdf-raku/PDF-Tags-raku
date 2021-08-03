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
my PDF::Tags::Elem $doc = $tags.add-kid: :name(Document);

is $doc.style.Str, "display:block; margin:8px; unicode-bidi:embed;", "document style";

my $h1 = $doc.add-kid: :name(Header1);
is $h1.style.Str, "display:block; font-size:2em; font-weight:bolder; margin-bottom:0.67em; margin-top:0.67em; unicode-bidi:embed;", "Header1 style";

my $h2 = $doc.add-kid: :name(Header2);
is $h2.style.Str, "display:block; font-size:1.5em; font-weight:bolder; margin-bottom:0.75em; margin-top:0.75em; unicode-bidi:embed;", "Header2 style";

my $span = $h2.add-kid: :name(Span);
is $h2.style.Str, "display:block; font-size:1.5em; font-weight:bolder; margin-bottom:0.75em; margin-top:0.75em; unicode-bidi:embed;", "Header2/Span style";

my $para = $doc.add-kid: :name(Paragraph);
is $para.style.Str, "display:block; margin-bottom:1.12em; margin-top:1.12em; unicode-bidi:embed;", "Paragraph style";

my $code-para = $para.add-kid: :name(Code);
is $code-para.style.Str, "font-family:monospace;", "Paragraph/Code style";
