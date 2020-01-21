class PDF::DOM::XPath {
    # tiny neophytic XPath like expression evaluator
    # currently handles: /<tag>[pos]?/ ...

    use PDF::DOM::Elem;
    use PDF::DOM::Node;

    has Str $.xpath is required;
    has &!compiled;

    our grammar Expression {
        rule TOP {
            [$<abs>='/']?
            [<expr=.name>[ '[' ~ ']' <expr=.filter> ]?]+ % <expr=.path>
        }
        proto rule name {*}
        rule name:sym<tag>  { <tag=.ident> }
        rule name:sym<all>  { '*' }

        proto rule filter {*}
        token int { < + - >? \d+ }
        rule filter:sym<position> { <int> }

        rule path {'/'}

        our class Actions {
            method TOP($/) {
                make -> PDF::DOM::Node $ref is copy {
                    $ref .= root() if $<abs>;
                    my @set = $ref.kids;
                    for @<expr> {
                        my &query = .ast;
                        @set = &query(@set);
                    }
                    @set;
                }
            }
            method path($/){
                make -> @nodes {
                    my @kids;
                    @kids.append(.kids)
                        for @nodes;
                    @kids;
                }
            }
            method name:sym<tag>($/) {
                my $tag := ~$<tag>;
                make -> @nodes {
                    @nodes.grep(PDF::DOM::Elem).grep({.tag eq $tag; });
                }
            }
            method name:sym<all>($/) { make -> @elems { @elems } }

            method filter:sym<position>($/) {
                my $index := $<int>.Int;
                make -> @elems {
                    @elems[$index-1];
                }
            }
        }
    }

    submethod TWEAK {
        my Expression::Actions $actions .= new;
        fail "can't handle xpath: $!xpath"
           unless Expression.parse($!xpath, :$actions);
        &!compiled := $/.ast;
    }

    multi method find(PDF::DOM::Node :$ref!, Str:D :$xpath!) {
        self.new(:$xpath).find(:$ref);
    }

    multi method find(PDF::DOM::Node :$ref!) {
        &!compiled($ref);
    }

    multi method find(PDF::DOM :$dom!, |c) {
        self.find(ref => $dom.root, |c);
    }

}
