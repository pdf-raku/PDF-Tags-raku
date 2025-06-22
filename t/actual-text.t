use v6;
use Test;
plan 5;

use PDF::Class;
use PDF::Annot;
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
            my PDF::Annot $annot .= COERCE: {
                :Type(:name<Annot>),
                :Subtype(:name<Link>),
                :Rect[71, 717, 190, 734],
                :A{
                    :Type(:name<Action>),
                    :S(:name<URI>),
                    :URI<http://google.com>,
                }
            };
            my $link = $para.Link: $gfx, $annot;
            $link.mark: $gfx, {
                .print('http://google.com');
            }
            $para.mark: $gfx, {
                .say('.');
            }
            is $link.text, 'http://google.com';
            is $para.text, "This paragraph links to http://google.com.\n";
        }
    }

    subtest 'marking at higher level', {
        $section.P.mark: $gfx, {
            .say: 'Top level para.', :position[50, 480];
        }

        is $section.text, "This paragraph links to http://google.com.\nTop level para.\n";
    }

    is $doc.xml, q:to<END>, 'xml';
    <Document>
      <Sect>
        <P>
          This paragraph links to <Link href="http://google.com">http://google.com</Link>.
        </P>
        <P>
          Top level para.
        </P>
      </Sect>
    </Document>
    END
}

# ensure consistant document ID generation
$pdf.id =  $*PROGRAM.basename.fmt('%-16.16s');

lives-ok { $pdf.save-as: "t/actual-text.pdf", :!info; }

done-testing;
