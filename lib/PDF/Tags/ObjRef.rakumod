use PDF::Tags::Item :&build-item;

class PDF::Tags::ObjRef is PDF::Tags::Item {
    use PDF::OBJR;
    use PDF::StructElem;
    submethod TWEAK {
        self.Pg = $_ with self.value.Pg;
    }
    has PDF::Tags::Item $!parent;
    method parent {
        $!parent //= do with $.value.object.struct-parent {
            build-item($.root.parent-tree[$_+0], :$.Pg, :parent($.root));
        }
    }
    method value(--> PDF::OBJR) handles<object> { callsame() }

    method name { '#ref' }
}

=begin pod
=end pod
