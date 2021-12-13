use v6;
use Test;
plan 5;

use PDF::Class;
use PDF::Page;
use PDF::Tags;
use PDF::Tags::Elem;

my PDF::Class $pdf .= new;

my PDF::Page $page = $pdf.add-page;
my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.Document;

$page.graphics: -> $gfx {
    my $section = $doc.Section;
    
    $gfx.text: {
        my PDF::Tags::Elem $para = $section.P: $gfx, {
            .print('This paragraph links to ',
                   :verbatim,
                   :font-size(15),
                   :position[50, 520]);
        };
        is $para.text, 'This paragraph links to ';

        subtest 'marking at lower level', {
            my PDF::Tags::Elem $link = $para.Link: $gfx, {
                .print('http://google.com');
            }
            $para.mark: $gfx, {
                .print('. ');
            }
            is $link.text, 'http://google.com';
            is $para.text, 'This paragraph links to http://google.com. ';
        }
    }

    subtest 'marking at higher level', {
        $section.mark: $gfx, {
            .print: 'top level text', :position[50, 420];
        }

        is $section.text, 'This paragraph links to http://google.com. top level text';
    }

    is $doc.xml, q{<Document>
  <Sect>
    <P>
      This paragraph links to
      <Link>http://google.com</Link>
      .
    </P>
    top level text
  </Sect>
</Document>
}, 'xml';
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM-NAME.fmt('%-16.16s');

lives-ok { $pdf.save-as: "t/actual-text.pdf", :!info; }

done-testing;
