role PDF::Tags::Node::Root {
    use PDF::StructTreeRoot;
    method cos(--> PDF::StructTreeRoot) { callsame() }
    method parent      { fail "already at root" }
    method name        { '#root' }
    method read        {...}
    method marks       {...}
    method class-map   {...}
    method role-map    {...}
    method parent-tree {...}
    method protect     {...}
}

=begin pod
=end pod
