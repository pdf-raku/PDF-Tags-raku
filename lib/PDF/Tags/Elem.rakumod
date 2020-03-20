use PDF::Tags::Node;

class PDF::Tags::Elem is PDF::Tags::Node {

    use PDF::COS;
    use PDF::COS::Dict;
    use PDF::COS::Stream;
    use PDF::Content;
    use PDF::Content::Graphics;
    use PDF::Tags::Item :&build-item;
    use PDF::Tags::ObjRef;
    use PDF::Tags::Mark;
    # PDF:Class
    use PDF::OBJR;
    use PDF::Page;
    use PDF::StructElem;
    use PDF::XObject;
    use PDF::XObject::Image;
    use PDF::XObject::Form;
    use PDF::Class::StructItem;

    method cos(--> PDF::StructElem) { callsame() }
    has PDF::Tags::Node $.parent is rw = self.root;
    has %!attributes;
    has Bool $!atts-built;
    has Str $.name is built;
    has Str $.class is built;
    has Bool $!hash-init;

    method attributes {
        $!atts-built ||= do {
            for $.cos.attribute-dicts -> Hash $atts {
                %!attributes{$_} = $atts{$_}
                    for $atts.keys
            }

            unless %!attributes {
                for $.cos.class-map-keys {
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

    method actual-text { $.cos.ActualText }

    method text { $.actual-text // $.kids.map(*.text).join }

    submethod TWEAK {
        self.Pg = $_ with self.cos.Pg;
        my Str:D $tag = self.cos.tag;
        with self.root.role-map{$tag} {
            $!class = $tag;
            $!name = $_;
        }
        else {
            $!name = $tag;
        }
    }

    method mark(PDF::Content $gfx, &action, :$name = self.name, |c) {
        my $kid = self.add-kid: $gfx.tag($name, &action, :mark, |c);
        given $gfx.parent {
            when PDF::Page {
                my $idx = (.StructParents //= $.root.parent-tree.max-key + 1);
                $.root.parent-tree[$idx+0][$kid.mcid] //= self.cos;
            }
            default {
                warn "ignoring mark call on {.WHAT.raku} object";
            }
        }
        $kid;
    }

    # build intermediate node
    multi method copy-tree(PDF::Tags::Elem $from-elem = self, PDF::XObject::Form:D :$Stm!, :$parent!) {
         my PDF::StructElem $from-cos = $from-elem.cos;
        my $S = $from-cos.S;
        my PDF::StructElem $P = $parent.cos;
        my PDF::StructElem $to-cos =  PDF::COS.coerce: %(
            :Type( :name<StructElem> ),
            :$S,
            :$P,
            :$.Pg,
            :$Stm,
        );
        for <A C T Lang Alt E ActualText> -> $k {
            $to-cos{$k} = $_ with $from-cos{$k};
        }
        my PDF::Tags::Elem $to-elem = build-item($to-cos, :$.root, :$parent);
        for $from-elem.kids {
            my PDF::Tags::Item:D $kid = $.copy-tree($_, :$Stm, :parent($to-elem));
            $to-elem.add-kid: $kid;
        }
        $to-elem;
    }

    # build leaf nodes
    multi method copy-tree(PDF::Tags::Mark $item, PDF::COS::Stream :$Stm!) {
        $item.clone: :$Stm, :parent(PDF::Tags::Elem);
    }
    multi method copy-tree(PDF::Tags::ObjRef $ref) {
        $ref.cos;
    }

    multi method do(PDF::Content $gfx, PDF::XObject $xobj where .StructParent.defined, |c) {
        my @rect = $gfx.do($xobj, |c);
        self.reference($gfx, $xobj);
        self!bbox($gfx, @rect);
        @rect;
    }

    multi method do(PDF::Content $gfx, PDF::XObject::Image $img, |c) {
        my @rect = $gfx.do($img, |c);
        self!bbox($gfx, @rect);
        @rect;
    }

   multi method do(PDF::Content $gfx, PDF::XObject::Form $xobj, |c) {
        my @rect = $gfx.do($xobj, |c);

        my $owner = $gfx.owner;
        my PDF::Page $Pg = $owner
            if $owner ~~ PDF::Page;

        with $xobj.StructParents {
            # avoid rendering the xobject, if possible; likely to
            # work better with foreign xobjects
            my Array $parents = self.root.parent-tree[$_+0];

            for $parents.keys {
                # copy sub-trees
                my PDF::StructElem $cos = $parents[$_];
                my PDF::Tags::Elem $elem = build-item($cos, :$.root, :$Pg, :parent(self));
                self.add-kid: $elem.copy-tree(:Stm($xobj), :parent(self));
                
            }
        }
        else {
            # build marked content tags from the xobject
            self!finish-form: $xobj, :$owner, :parent(self);
        }

        self!bbox($gfx, @rect);
        @rect;
    }

    method !finish-form(PDF::XObject::Form $content, PDF::Content::Graphics :$owner!) {
        my PDF::Content::Tag @tags = $content.gfx.tags.descendants.grep(*.mcid.defined);
        if @tags {
            $content.StructParents //= do {
                my PDF::Page $Pg = $owner
                    if $owner ~~ PDF::Page;
               my UInt $idx := $.root.parent-tree.max-key + 1;
                my @parents =  @tags.map: {
                    my PDF::Content::Tag $mark = .clone(:$owner, :$content);
                    my $name = $mark.name;
                    my $kid = self.add-kid($name, :$Pg);
                    $kid.add-kid: $mark;
                    $kid;
                }
                $.root.parent-tree[$idx] = [ @parents.map(*.cos) ];
                $idx;
            }
        }
    }

    method !bbox($gfx, @rect) {
        self.set-bbox($gfx, @rect)
            if self.name ~~ 'Figure'|'Form'|'Table'|'Formula';
    }

    method set-bbox(PDF::Content $gfx, @rect) {
        self.attributes<BBox> = $gfx.base-coords(@rect).Array;
    }

    method reference(PDF::Content $gfx, PDF::Class::StructItem $Obj) {
        my PDF::Page $Pg = $gfx.owner;
        self.add-kid: PDF::COS.coerce: %(
            :Type( :name<OBJR> ),
            :$Obj,
            :$Pg;
        );
        without $Obj.StructParent {
            $_ = $.root.parent-tree.max-key + 1;
            $.root.parent-tree[$_ + 0] = self.cos;
        }
        self;
    }
}

=begin pod
=end pod
