role PDF::Tags::Root {
    use PDF::StructTreeRoot;
    method value(--> PDF::StructTreeRoot) { callsame() }
    method parent { fail "already at root" }
    method tag { '#root' }
    method read        {...}
    method marks       {...}
    method class-map   {...}
    method role-map    {...}
    method parent-tree {...}
}

=begin pod
=end pod
