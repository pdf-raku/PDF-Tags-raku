module DtD {
    # resources take from the ISO-32000 PDF specification
    constant BLSE    = set <P H1 H2 H3 H4 H5 H6 L LI Lbl LBody Table>;
    constant ILSE    = set <Span Quote Note Reference BibEntry Code Link Annot Ruby Warichu>;
    constant GROUP   = set <Document Part Art Sect Div BlockQuote Caption TOC TOCI Index NonStruct Private>;
    constant WARICHU = set <WT WP>;
    constant RUBY    = set <RB RT RP>;
    our sub load-elems(%ents) {
        my %elems;
        # resources taken from https://accessible-pdf.info/basics/general/overview-of-the-pdf-tags
        for "src".IO.dir.grep({.ends-with(".csv")}) {
            my $d = .slurp;
            for $d.lines.skip {
                my ($elems, $desc, $parents, $kids) = .split: "\t";
                my @parents = $parents
                    .subst('H1–H6', {('H1'..'H6').join: ', '})
                    .split(", ");
                my @kids = $kids.split(", ")
                            if $kids.defined && $kids ~~ /^[<alnum>+] * % ', '$/;
                for $elems.split(", ") -> $e {
                    %elems{$e} //= %();
                    for @parents -> $p {
                        %elems{$p}{$e}++
                            unless $p eq '–';
                    }
                    for @kids -> $k {
                        %elems{$e}{$k}++
                    }
                }
            }
        }
        # vivify inline elements
        for %ents<Inline>.Slip {
            %elems{$_}<#PCDATA>++;
            %elems{$_}<%Inline;>++;
        }

        # Populate some elements no specifically covered in the CSV files
        %elems<Warichu>{$_}++ for WARICHU.keys;
        %elems<Ruby>{$_}++ for RUBY.keys;
        %elems{$_}<Span>++ for WARICHU.keys.Slip, RUBY.keys.Slip;
        for GROUP.keys -> $grp {
            for BLSE.keys -> $blk {
                %elems{$grp}{$blk}++;
            }
        }
        for GROUP.keys.Slip, BLSE.keys.Slip {
            %elems<NonStruct>{$_}++;
            %elems<Private>{$_}++;
        }
        %elems{$_}<%Inline;>++ for <H Lbl TH TD Caption>;

        for %elems.values {
            .<#PCDATA>++ if (.<Span>:exists) || (.<%Inline;>:exists);
            $_ ||= %( :EMPTY );
        }
        %elems;
    }

    our sub reconcile(%elems, %ents) {
        my %refs;
        %refs{$_}++ for %elems.values.map: {.keys.Slip};
        %refs{$_}++ for %ents.values.map: *.Slip;
        %refs{$_}:delete
            for %elems.keys;
        %refs{'%' ~ $_ ~ ';'}:delete
            for %ents.keys;
        %refs{$_}:delete
            for <#PCDATA ANY EMPTY>;

        die join "\n", ("unresolved references:", %refs.keys.sort.Slip)
            if %refs;
    }    

    our sub output(%elems, %ents, %atts) {
        say q:to<END>;
        <!-- Non normative XML DtD for tagged PDF XML serialization. Based on:
              - PDF ISO-32000 1.7 Specification,
                - Section 14.8.4 Standard Structure Types
                - Section 14.8.5 Standard Structure Attributes
              - https://accessible-pdf.info/basics/general/overview-of-the-pdf-tags

             Not applying ordering or arity constraints on child nodes
        -->
        END

        for %ents.sort {
            my $k = .key;
            my $v = .value;
            my @v = .value.sort;
            for %elems.values -> %kids {
                if all(@v.map: {%kids{$_}:exists}) {
                    %kids{@v}:delete;
                    %kids{'%' ~ $k ~ ';'}++;
                }
            }
            # bring in additional entities mentioned in the artical, but not fully specced;
            my @mentions = do given $k {
                when 'Hdr' {'H'}
                when 'Inline' { DtD::ILSE.keys.grep: {$v{$_}:!exists} }
                default { [] }
            }
            if @mentions {
                @v.append: @mentions;
                %ents{$k} = @v.sort.unique;
            }
            say "<!ENTITY \% $k \"{@v.join: '|'}\">";
        }

        say '';

        for %elems.keys.sort -> $k {
            my @v = %elems{$k}.keys.sort;
            say "<!ELEMENT $k ({@v.join: '|'})*>";
            with %atts{$k}.sort.unique {
                say "<!ATTLIST $k {.join: ' '}>";
            }
            say '';
        }
    }

}

our %ents = :Hdr<H1 H2 H3 H4 H5 H6>,
            :SubPart<Art Sect Div>,
            :Inline(
                <Span Quote Note Reference Code Link Annot Formula>.Slip,
                DtD::BLSE.keys.Slip),
            :Block<BlockQuote Caption Figure Form Formula Index L P TOC Table>,
            :StructMisc<NonStruct Private>,
            :DocFrag<Document Part Art Sect Div>,
            ;

my %elems = DtD::load-elems(%ents);
my %atts;
DtD::reconcile(%elems, %ents);
%ents<attsAny> = (
    "",
    "Placement (Block|Inline|Before|Start|End) #IMPLIED",
    "WritingMode (LrTb|RlTb|TbRl) 'LrTb'",
    "BackgroundColor CDATA #IMPLIED",
    "BorderColor CDATA #IMPLIED",
    "BorderStyle CDATA #IMPLIED",
    "BorderThickness CDATA #IMPLIED",
    "Padding CDATA #IMPLIED",
    "Color CDATA #IMPLIED",
    "role CDATA #IMPLIED",
).join: "\n\t";
%ents<attsBLSE> = (
    "",
    "SpaceBefore CDATA #IMPLIED",
    "SpaceAfter CDATA #IMPLIED",
    "StartIndent CDATA #IMPLIED",
    "EndIndent CDATA #IMPLIED",
    "TextIndent CDATA #IMPLIED",
    "TextAlign (Start|Center|End|Justify) 'Start'",
    "BBox CDATA #IMPLIED",
    "Width CDATA #IMPLIED",
    "Height CDATA #IMPLIED",
    "BlockAlign (Before|Middle|After|Justify) 'Before'",
    "InlineAlign (Start|Center|End) 'Start'",
    "TBorderStyle CDATA #IMPLIED",
    "TPadding CDATA #IMPLIED",
    "class CDATA #IMPLIED",
).join: "\n\t";
%ents<attsILSE> = (
    "",
    "BaselineShift CDATA #IMPLIED",    
    "LineHeight CDATA #IMPLIED",    
    "TextDecorationColor CDATA #IMPLIED",    
    "TextDecorationThickness CDATA #IMPLIED",
    "TextDecorationType (None|Underline|Overline|LineThrough) 'None'",
    "RubyName (Start|Center|End|Justify|Distribute) 'Distribute'",
    "RubyPosition (Before|After|Warichu|Inline) 'Before'",
    "GlyphOrientationVertical CDATA #IMPLIED",
).join: "\n\t";
%ents<attsCell> = (
    "",
    "RowSpan CDATA #IMPLIED",
    "ColSpan CDATA #IMPLIED",
    "Headers CDATA #IMPLIED",
    "Scope (Row|Column|Both) #IMPLIED",
    "Width CDATA #IMPLIED",
    "Height CDATA #IMPLIED",
    "BlockAlign (Before|Middle|After|Justify) 'Before'",
    "InlineAlign (Start|Center|End) 'Start'",
    "TBorderStyle CDATA #IMPLIED",
    "TPadding CDATA #IMPLIED",
).join: "\n\t";
%ents<attsCols> = (
    "",
    "ColumnCount CDATA #IMPLIED",
    "ColumnGap CDATA #IMPLIED",
    "ColumnWidths CDATA #IMPLIED",
).join: "\n\t";
%ents<attsRuby> = (
    "",
    "RubyAlign (Start|Center|End|Justify|Distribute) 'Distribute'"
).join: "\n\t";
%ents<attsTable> = (
    "",
    "Summary CDATA #IMPLIED",
).join: "\n\t";
%ents<attsList> = (
    "",
    "ListNumbering (None|Disc|Circle|Square|Decimal|UpperRoman|LowerRoman|UpperAlpha|LowerAlpha) 'None'",
).join: "\n\t";
%atts{$_}.push: '%attsAny;' for %elems.keys;
%atts{$_}.push: '%attsBLSE;' for DtD::BLSE.keys;
%atts{$_}.push: '%attsILSE;' for DtD::ILSE.keys.Slip, DtD::BLSE.keys.Slip;
%atts{$_}.push: '%attsCols;' for <Art Sect Div>;
%atts<L>.push: '%attsList;', for <L>;
%atts{$_}.push: '%attsCell;' for <TH TD>;
%atts{$_}.push: '%attsRuby;' for DtD::RUBY.keys;
%atts<Link>.push: 'href CDATA #IMPLIED';
%atts<Table>.push: '%attsTable;' for <Table TR TH TD THead TBody TFoot>;

# BLSE attributes are only applicable to ILSEs with Placement
# other than inline
%atts{$_}.push: '%attsBLSE;' for DtD::ILSE.keys;

DtD::output(%elems, %ents, %atts);
