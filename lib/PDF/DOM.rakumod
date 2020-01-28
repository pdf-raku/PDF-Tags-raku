
class PDF::DOM {
    use PDF::Class;
    use PDF::Page;
    use PDF::NumberTree :NumberTree;
    use PDF::StructElem;
    use PDF::StructTreeRoot;
    subset StructNode of Hash is export(:StructNode) where PDF::Page|PDF::StructElem;

    has Hash $.class-map;
    has Hash $.role-map;
    has NumberTree $.parent-tree;
    has %!deref{Any};
    has Bool $.render = True;
    has Bool $.strict = True;
    has $.root is built handles<elems AT-POS Array kids first find tag>;

    my class Cache {
        has %.font{Any};
    }
    has Cache $!cache .= new;

    multi submethod TWEAK(PDF::StructTreeRoot :$root!) {
        $!class-map = $_ with $root.ClassMap;
        $!role-map = $_ with $root.RoleMap;
        $!parent-tree = .number-tree with $root.ParentTree;
        $!root = (require ::('PDF::DOM::Root')).new: :dom(self), :item($root);
    }

    multi submethod TWEAK(PDF::Class :$pdf!) {
        with $pdf.catalog.StructTreeRoot -> $root {
            self.TWEAK: :$root;
        }
        else {
            fail "document does not contain marked content";
        }
    }

    multi method deref(StructNode $_) {
        %!deref{$_} //= do with .struct-parent -> $i {
            with $.item.parent-tree {.[$i + 0]}
        } // $_;
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
            my PDF::Content::Tag % = $gfx.tags.grep(*.mcid.defined).map({.mcid => $_ });
        }
    }

}
