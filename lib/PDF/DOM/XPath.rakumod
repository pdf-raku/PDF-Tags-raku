class PDF::DOM::XPath {
    # tiny neophytic XPath like expression evaluator
    # currently handles: /<tag>[pos]?/ ...

    use PDF::DOM::Item;

    has Str $.xpath is required;
    has &!compiled;

    our grammar Expression {
        rule TOP { [$<abs>='/']? <step>+ % '/' }

        rule step { [ <axis> '::']? [ <node-test> [ '[' ~ ']' <predicate> ]?] }

        proto rule node-test {*}
        rule node-test:sym<tag> { <tag=.ident> }
        rule node-test:sym<any> { '*' }

        proto rule predicate {*}
        token int { < + - >? \d+ }
        rule predicate:sym<position> { <int> | 'position(' ~ ')'  <int> }

        proto rule axis {*}
        rule axis:sym<child>   { <sym> }

        our class Actions {
            method TOP($/) {
                make -> PDF::DOM::Item $ref is copy {
                    $ref .= root() if $<abs>;
                    my @set = ($ref,);
                    @set = (.ast)(@set)
                        for @<step>;
                    @set;
                }
            }
            method step($/) {
                my &axis := do with $<axis> { .ast } else { &child-axis };
                my &node-test := $<node-test>.ast;
                my &predicate = .ast with $<predicate>;

                make -> @set {
                    @set = gather {
                        for @set {
                            take $_ if &node-test($_)
                                for &axis($_);
                        }
                    };
                    &predicate.defined ?? &predicate(@set) !! @set;
                }
            }

            method node-test:sym<tag>($/) {
                my $tag := ~$<tag>;
                make -> PDF::DOM::Item $_ { .tag eq $tag; }
            }
            method node-test:sym<any>($/) { make -> $_ { $_ } }

            sub child-axis(PDF::DOM::Item $_) { .?kids // [] }
            method axis:sym<child>($/)    { make &child-axis }

            method predicate:sym<position>($/) {
                my $index := $<int>.Int;
                make -> @elems --> PDF::DOM::Item {
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

    multi method find(PDF::DOM::Item :$ref!, Str:D :$xpath!) {
        self.new(:$xpath).find(:$ref);
    }

    multi method find(PDF::DOM::Item :$ref!) {
        &!compiled($ref);
    }

    multi method find(PDF::DOM :$dom!, |c) {
        self.find(ref => $dom.root, |c);
    }

}
