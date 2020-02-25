use PDF::Tags::Node;

class PDF::Tags::Elem is PDF::Tags::Node {
    use PDF::StructElem;
    use PDF::Tags::Mark;

    method value(--> PDF::StructElem) { callsame() }
    has $.parent is required;
    has %!attributes;
    has Bool $!atts-built;
    has Str $.tag is built;
    has Str $.class is built;
    has Bool $!hash-init;
    method attributes {
        $!atts-built ||= do {
            for $.value.attribute-dicts -> $atts {
                %!attributes{$_} = $atts{$_}
                for $atts.keys
            }

            unless %!attributes {
                for $.value.class-map-keys {
                    with $.dom.class-map{$_} -> $atts {
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
            when ! $.dom.marks && $_ ~~ PDF::Tags::Mark {
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
        with self.dom.role-map{$tag} {
            $!class = $tag;
            $!tag = $_;
        }
        else {
            $!tag = $tag;
        }
    }
}
