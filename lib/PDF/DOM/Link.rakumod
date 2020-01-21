use PDF::DOM::Node;
use PDF::OBJR;
class PDF::DOM::Link is PDF::DOM::Item {
    submethod TWEAK {
        self.Pg = $_ with self.item.Pg;
    }
    method item(--> PDF::OBJR) handles<object> { callsame() }
    method parent { fail ".parent() not applicable to Links" }
    method tag { '#ref' }
}
