use PDF::DOM::Node;
use PDF::OBJR;
class PDF::DOM::ObjRef is PDF::DOM::Item {
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
    method value(--> PDF::OBJR) handles<object> { callsame() }
    method parent { fail ".parent() not applicable to Object Refs" }
    method tag { '#ref' }
}
