use PDF::Tags::Node;
use PDF::Tags::Root;

class PDF::Tags:ver<0.0.1>
    is PDF::Tags::Node
    does PDF::Tags::Root {

    use PDF::Class:ver<0.4.1+>;
    use PDF::Page;
    use PDF::NumberTree :NumberTree;
    use PDF::COS;
    use PDF::StructElem;
    use PDF::StructTreeRoot;

    has Hash $.class-map         is built;
    has Hash $.role-map          is built;
    has NumberTree $.parent-tree is built;
    has Bool $.render = True;
    has Bool $.strict = True;
    has Bool $.marks;
    method root { self }

    my class Cache {
        has %.font{Any};
    }
    has Cache $!cache .= new;

    submethod TWEAK(PDF::StructTreeRoot :$value!) {
        $!class-map = $_ with $value.ClassMap;
        $!role-map = $_ with $value.RoleMap;
        $!parent-tree = .number-tree
            given $value.ParentTree //= { :Nums[] };
    }

    method read(PDF::Class :$pdf!, Bool :$create) {
        with $pdf.catalog.StructTreeRoot -> $value {
            self.new: :$value, :root(self.WHAT);
        }
        else {
            $create
                ?? self.create(:$pdf)
                !! fail "document does not contain marked content";
        }
    }

    method create(
        PDF::StructTreeRoot :$value = PDF::COS.coerce({ :Type( :name<StructTreeRoot> )}),
        PDF::Class :$pdf,
    ) {
        $value.check;

        with $pdf {
            with .catalog.StructTreeRoot {
                fail "document already contains marked content";
            }
            else {
                $_ = $value;
            }
            .<Marked> = True
                given .Root<MarkInfo> //= {};
        }
        self.new: :$value, :root(self.WHAT), :marks;
    }

    class TextDecoder {
        use PDF::Content::Ops :OpCode;
        has Hash @!save;
        has $.current-font;
        has Cache $.cache is required;
        method !load-font(Hash $dict) {
            $!cache.font{$dict} //= (require ::('PDF::Font::Loader')).load-font: :$dict;
        }

        method current-font { $!current-font[0] }
        method callback {
            sub ($op, *@args) {
                my $method = OpCode($op).key;
                self."$method"(|@args)
                    if $method ~~ 'Save'|'Restore'|'SetFont'|'ShowText'|'ShowSpaceText'|'Do';
            }
        }
        method Save()      {
            @!save.push: %( :$!current-font );
        }
        method Restore()   {
            if @!save {
                with @!save.pop {
                    $!current-font = .<current-font>;
                }
            }
        }
        method SetFont(Str $font-key, Numeric $font-size) {
            with $*gfx.resource-entry('Font', $font-key) -> $dict {
                $!current-font = self!load-font($dict);
            }
            else {
                warn "unable to locate Font in resource dictionary: $font-key";
                $!current-font = PDF::Content::Util::Font.core-font('courier');
            }
        }
        method ShowText($text-encoded) {
            .children.push: $!current-font.decode($text-encoded, :str)
                with $*gfx.open-tags.tail;
        }
        method ShowSpaceText(List $text) {
            with $*gfx.open-tags.tail -> $tag {
                my Str $last := ' ';
                my @chunks = $text.map: {
                    when Str {
                        $last := $!current-font.decode($_, :str);
                    }
                    when $_ <= -120 && !($last ~~ /\s$/) {
                        # assume implicit space
                        ' '
                    }
                    default { '' }
                }
                $tag.children.push: @chunks.join;
            }
        }
        method Do($key) {
            warn "todo Do $key";
        }
    }
    constant Tags = Hash[PDF::Content::Tag];
    has Tags %!graphics-tags{PDF::Content::Graphics};

    method graphics-tags($obj) {
        return unless $!render;
        %!graphics-tags{$obj} //= do {
            $*ERR.print: '.';
            my &callback = TextDecoder.new(:$!cache).callback;
            my $gfx = $obj.gfx: :&callback, :$!strict;
            $obj.render;
            my PDF::Content::Tag % = $gfx.tags.grep(*.mcid.defined).map: {.mcid => $_ };
        }
    }

}

=begin pod
=head1 NAME

PDF::Tags - Tagged PDF root node

=head1 SYNOPSIS

```
use PDF::Content::Tag :ParagraphTags;
use PDF::Class;
use PDF::Tags;
use PDF::Tags::Elem;

# create tags
my PDF::Class $pdf .= new;

my $page = $pdf.add-page;
my $font = $page.core-font: :family<Helvetica>, :weight<bold>;
my $body-font = $page.core-font: :family<Helvetica>;

my PDF::Tags $tags .= create: :$pdf;
my PDF::Tags::Elem $doc = $tags.add-kid(Document);

$page.graphics: -> $gfx {
    $doc.add-kid(Paragraph).mark: $gfx, {
        .say('Hello tagged world!',
             :$font,
             :font-size(15),
             :position[50, 120]);
    }
}
$pdf.save-as: "t/pdf/tagged.pdf";

# read tags
my PDF::Class $pdf .= open: "t/pdf/tagged.pdf");
my PDF::Tags $tags .= read: :$pdf;
my PDF::Tags::Elem $doc = $tags[0];

# search tags
my PDF::Tags @elems = $tags.find('Document//*');
```

=head1 DESCRIPTION

A tagged PDF contains additional markup information describing the logical
document structure.

=end pod
