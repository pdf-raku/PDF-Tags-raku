class PDF::DOM::XPath {
    # tiny neophytic XPath like expression evaluator
    # currently handles: /<tag>[pos]?/ ...

    use PDF::DOM::Item;
    use PDF::DOM::Elem;
    use PDF::DOM::Tag;

    has Str $.xpath is required;
    has &!compiled;

    our subset Node of PDF::DOM::Item where PDF::DOM::Elem|PDF::DOM::Tag;

    our grammar Expression {
        rule TOP { [$<abs>='/']? <step>+ % '/' }

        rule step { [ <axis> ]? <node-test> <predicate>? }

        proto rule node-test {*}
        rule node-test:sym<tag> { <tag=.ident> }
        rule node-test:sym<node> { '*' }

        rule predicate         { '[' ~ ']' <query(4)> }
        multi rule query(0)     { <term> }
        multi rule query($pred) { <term=.query($pred-1)> +% <q-op($pred-1)> }

        # query operators - loosest to tightest
        multi token q-op(3) {or}
        multi token q-op(2) {and}
        multi token q-op(1) {'='|'!='}
        multi token q-op(0) {['<'|'>']'='?}

        token int { < + - >? \d+ }
        proto rule term {*}
        rule term:sym<int> { <int> }
        rule term:sym<position> { 'position(' ')' }
        rule term:sym<query> { '(' ~ ')' <query(4)> }

        proto rule axis {*}
        rule axis:sym<child>   { <sym> '::' }

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
                    }
                    @set = ($_)(@set) with &predicate;
                    @set;
                }
            }

            method predicate($/) {
                make -> @set {
                    my &query = $<query>.ast;
                    my $*position = 0;
                    my $*last = +@set;
                    @set = gather {
                        for @set {
                            ++$*position;
                            my $v := &query();
                            take $_ if ($v ~~ Bool && $v)
                               || ($v ~~ Int &&  $v == $*position);
                        }
                    }
                }
            }

            method node-test:sym<tag>($/) {
                my $tag := ~$<tag>;
                make -> PDF::DOM::Item $_ { .?tag eq $tag; }
            }
            method node-test:sym<node>($/) { make -> PDF::DOM::Item $_ { $_ ~~ Node} }

            sub child-axis(PDF::DOM::Item $_) { .?kids // [] }
            method axis:sym<child>($/)    { make &child-axis }

            method int($/) { make $/.Int }
            method q-op($/)  { make $/.lc }
            method query($/) {
                my @terms;
                my @ops;
                if $<term> ~~ Array {
                    @terms = @<term>>>.ast;
                    @ops = @<q-op>>>.ast;
                }
                else {
                    @terms.push: $<term>.ast;
                }
                make -> {
                    my $a := (@terms[0]).();

                    for 1 ..^ @terms -> $i {
                        my $b := (@terms[$i]).();
                        $a := do given @ops[$i-1] {
                            when 'or'  { $a or  $b }
                            when 'and' { $a and $b }
                            when '='   { $a ==  $b }
                            when '!='  { $a !=  $b }
                            when '<'   { $a <   $b }
                            when '<='  { $a <=  $b }
                            when '>'   { $a >   $b }
                            when '>='  { $a >=  $b }
                            default { die "unhandled operator: '$_'" }
                        }
                    }
                    $a;
                }
            }
            method term:sym<int>($/) {
                my Int:D $v = $<int>.ast;
                make -> { $v; }
            }
            method term:sym<position>($/) {
                make -> { $*position; }
            }
            method term:sym<query>($/) {
                make $<query>.ast;
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
