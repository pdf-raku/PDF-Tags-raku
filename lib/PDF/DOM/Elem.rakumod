use PDF::DOM::Node;
use PDF::StructElem;
class PDF::DOM::Elem is PDF::DOM::Node {
    method item(--> PDF::StructElem) { callsame() }
    has $.parent is required;
    has Str  %!attributes;
    has Bool $!atts-built;
    has Str $.tag is built;
    has Str $.class is built;
    method attributes handles<AT-KEY> {
        $!atts-built ||= do {
            for $.item.attribute-dicts -> $atts {
                %!attributes{$_} = $atts{$_}
                for $atts.keys
            }

            unless %!attributes {
                for $.item.class-map-keys {
                    with $.dom.class-map{$_} -> $class {
                        %!attributes{$_} = $class{$_}
                        for $class.keys
                    }
                }
            }

            %!attributes<class> = $_ with $!class;

            True;
        }

        %!attributes;
    }
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
        my Str:D $tag = self.item.tag;
        with self.dom.role-map{$tag} {
            $!class = $tag;
            $!tag = $_;
        }
        else {
            $!tag = $tag;
        }
    }
}
