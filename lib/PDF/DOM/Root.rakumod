use PDF::DOM::Node;
use PDF::StructTreeRoot;
class PDF::DOM::Root is PDF::DOM::Node {
    method item(--> PDF::StructTreeRoot) { callsame() }
    method parent { fail "already at root" }
    method tag { '#root' }
}
