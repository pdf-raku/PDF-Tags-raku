use PDF::Tagged::Node;
use PDF::OBJR;
class PDF::Tagged::ObjRef is PDF::Tagged::Item {
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
    method value(--> PDF::OBJR) handles<object> { callsame() }
    method parent { fail ".parent() not applicable to Object Refs" }
    method tag { '#ref' }
}
