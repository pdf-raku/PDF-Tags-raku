role PDF::Tags::Root {
    use PDF::StructTreeRoot;
    method value(--> PDF::StructTreeRoot) { callsame() }
    method parent { fail "already at root" }
    method tag is DEPRECATED<name> { $.name }
    method name { '#root' }
    method read        {...}
    method marks       {...}
    method class-map   {...}
    method role-map    {...}
    method parent-tree {...}
}

=begin pod
=end pod
