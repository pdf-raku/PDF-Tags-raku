use PDF::Tagged::Node;
use PDF::StructTreeRoot;
class PDF::Tagged::Root is PDF::Tagged::Node {
    method value(--> PDF::StructTreeRoot) { callsame() }
    method parent { fail "already at root" }
    method tag { '#root' }
}
