use PDF::Tags::Node;
use PDF::StructTreeRoot;
class PDF::Tags::Root is PDF::Tags::Node {
    method value(--> PDF::StructTreeRoot) { callsame() }
    method parent { fail "already at root" }
    method tag { '#root' }
}
