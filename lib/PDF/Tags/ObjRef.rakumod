use PDF::Tags::Item :&build-item;

class PDF::Tags::ObjRef is PDF::Tags::Item {
    use PDF::OBJR;
    use PDF::StructElem;
    submethod TWEAK {
        self.Pg = $_ with self.cos.Pg;
    }
    has PDF::Tags::Item $!parent;
    method parent {
        $!parent //= do with $.cos.object.struct-parent {
            build-item($.root.parent-tree[$_+0], :$.Pg, :parent($.root));
        }
    }
    method cos(--> PDF::OBJR) handles<object> { callsame() }

    method name { '#ref' }
}

=begin pod
=end pod
