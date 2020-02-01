use PDF::Tags::Node;
use PDF::OBJR;
class PDF::Tags::ObjRef is PDF::Tags::Item {
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
    method value(--> PDF::OBJR) handles<object> { callsame() }
    method parent { fail ".parent() not applicable to Object Refs" }
    method tag { '#ref' }
}
