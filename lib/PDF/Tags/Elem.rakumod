use PDF::Tags::Node;

class PDF::Tags::Elem is PDF::Tags::Node {

    use PDF::COS;
    use PDF::OBJR;
    use PDF::Page;
    use PDF::StructElem;
    use PDF::Class::StructItem;
    use PDF::Tags::Mark;

    method value(--> PDF::StructElem) { callsame() }
    has $.parent is required;
    has %!attributes;
    has Bool $!atts-built;
    has Str $.name is built;
    has Str $.class is built;
    has Bool $!hash-init;

    method attributes {
        $!atts-built ||= do {
            for $.value.attribute-dicts -> Hash $atts {
                %!attributes{$_} = $atts{$_}
                    for $atts.keys
            }

            unless %!attributes {
                for $.value.class-map-keys {
                    with $.root.class-map{$_} -> $atts {
                        %!attributes{$_} = $atts{$_}
                            for $atts.keys
                    }
                }
            }

            %!attributes<class> = $_ with $!class;

            True;
        }

        %!attributes;
    }
 
   method build-kid($) {
        given callsame() {
            when ! $.root.marks && $_ ~~ PDF::Tags::Mark {
                # skip marked content tags. just get the aggregate text
                $.build-kid(.text);
            }
            default {
                $_;
            }
        }
    }

    method Hash {
       my $store := callsame();
       $!hash-init //= do {
           $store{'@' ~ .key} = .value
               for self.attributes.pairs;
           True;
       }
       $store;
    }

    multi method AT-KEY(Str $_ where .starts-with('@')) {
        self.attributes{.substr(1)};
    }

    method actual-text { $.value.ActualText }

    method text { $.actual-text // $.kids.map(*.text).join }

    submethod TWEAK {
        self.Pg = $_ with self.value.Pg;
        my Str:D $tag = self.value.tag;
        with self.root.role-map{$tag} {
            $!class = $tag;
            $!name = $_;
        }
        else {
            $!name = $tag;
        }
    }

    method mark(PDF::Content $gfx, &action, |c) {
        my $kid = $gfx.tag(self.name, &action, :mark, |c);
        self.add-kid: $kid;
    }

    method do(PDF::Content $gfx, PDF::Content::XObject $xobj, Bool :$marks, |c) {
        my @rect = $gfx.do($xobj, |c);

        if $marks && $xobj ~~ PDF::Content::XObject['Form'] {
            # import marked content tags from the xobject
            my $owner = $gfx.owner;
            my PDF::Content::Tag @tags = $xobj.gfx.tags.descendants.grep(*.mcid.defined);
            for @tags {
                my PDF::Content::Tag $mark = .clone(:$owner, :content($xobj));
                my $name = $mark.name;
                my $kid = self.add-kid($name);
                $kid.add-kid: $mark;
            }
        }

        self.set-bbox($gfx, @rect)
            if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';

        @rect;
    }

    method set-bbox(PDF::Content $gfx, @rect) {
        self.attributes<BBox> = $gfx.base-coords(@rect).Array;
    }

    method !obj-ref(PDF::Class::StructItem $Obj, PDF::Page :$Pg! --> PDF::OBJR:D) {
        my $parent-tree := $.root.parent-tree;
        with $Obj.struct-parent {
            # already has a struct-parents entry
            $parent-tree[$_ + 0];
        }
        else {
            # create a new struct-parents entry
            my $idx := $Obj.struct-parent = $parent-tree.max-key + 1;
            $parent-tree[$idx + 0] = PDF::COS.coerce: %(
                :Type( :name<OBJR> ),
                :$Obj,
                :$Pg;
            );
        }
    }

    method reference(PDF::Content $gfx, PDF::Class::StructItem $object, |c) {
        my PDF::Page $Pg = $gfx.owner;
        self.add-kid: self!obj-ref($object, :$Pg);
    }

}

=begin pod
=end pod
