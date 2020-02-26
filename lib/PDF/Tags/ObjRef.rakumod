use PDF::Tags::Item :&build-item;

class PDF::Tags::ObjRef is PDF::Tags::Item {
    use PDF::OBJR;
    use PDF::StructElem;
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
    has PDF::Tags::Item $!parent;
    method parent {
        my $dom := $.dom;
        $!parent //= do with $.value.object.struct-parent {
            build-item($dom.parent-tree[$_+0], :$.Pg, :$dom, :parent($dom.root));
        }
    }
    method value(--> PDF::OBJR) handles<object> { callsame() }

    method tag { '#ref' }
}

=begin pod
=end pod
