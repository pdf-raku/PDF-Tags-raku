class PDF::DOM::XPath {
    # small neophytic XPath like expression evaluator

    use PDF::DOM::Item;
    use PDF::DOM::Node;
    use PDF::DOM::Elem;
    use PDF::DOM::Tag;
    use PDF::DOM::Text;
    use PDF::DOM::XPath::Axis;

    has Str $.xpath is required;
    has &!compiled;

    our subset Elem of PDF::DOM::Node where PDF::DOM::Elem|PDF::DOM::Tag;
    constant Node = PDF::DOM::Item;
    constant Text = PDF::DOM::Text;

    our grammar Expression {
        rule TOP { [$<abs>='/']? <step>+ % '/' }

        proto rule step {*}
        rule step:sym<parent>    { '..' }
        rule step:sym<self>      { '.' }
        rule step:sym<regular>   { <axis> <node-test> <predicate>? }

        proto rule node-test {*}
        rule node-test:sym<tag>  { <tag=.ident> }
        rule node-test:sym<elem> { '*' }
        rule node-test:sym<node> { <sym> '(' ')' }
        rule node-test:sym<text> { <sym> '(' ')' }

        rule predicate           { '[' ~ ']' <query(4)> }
        multi rule query(0)      { <term> }
        multi rule query($pred)  { <term=.query($pred-1)> +% <q-op($pred-1)> }

        # query operators - loosest to tightest
        multi token q-op(3) {or}
        multi token q-op(2) {and}
        multi token q-op(1) {'='|'!='}
        multi token q-op(0) {['<'|'>']'='?}

        token int { < + - >? \d+ }
        proto rule term {*}
        rule term:sym<int> { <int> }
        rule term:sym<first>    { <sym> '(' ')' }
        rule term:sym<last>     { <sym> '(' ')' }
        rule term:sym<position> { <sym> '(' ')' }
        rule term:sym<query> { '(' ~ ')' <query(4)> }

        proto rule axis {*}
        rule axis:sym<ancestor>           { <sym> '::' }
        rule axis:sym<ancestor-or-self>   { <sym> '::' }
        rule axis:sym<child>              {[ <sym> '::' ]?}
        rule axis:sym<descendant>         {[ '/' | <sym> '::' ]}
        rule axis:sym<descendant-or-self> { <sym> '::' }
        rule axis:sym<following>          { <sym> '::' }
        rule axis:sym<following-sibling>  { <sym> '::' }
        rule axis:sym<preceding>          { <sym> '::' }
        rule axis:sym<preceding-sibling>  { <sym> '::' }
        rule axis:sym<parent>             { <sym> '::' }
        rule axis:sym<self>               { <sym> '::' }

        our class Actions {
            method TOP($/) {
                make -> PDF::DOM::Item:D $ref is copy {
                    $ref .= root() if $<abs>;
                    my @set = ($ref,);
                    @set = (.ast)(@set)
                        for @<step>;
                    @set;
                }
            }
            method step:sym<parent>($/) {
                make -> @set {
                    my @ = flat @set.map(&parent);
                }
            }
            method step:sym<self>($/)   { make -> @set { @set } }
            method step:sym<regular>($/) {
                my &axis := $<axis>.ast;
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
            method node-test:sym<elem>($/) { make -> PDF::DOM::Item $_ { $_ ~~ Elem} }
            method node-test:sym<node>($/) { make -> PDF::DOM::Item $_ { $_ ~~ Node} }
            method node-test:sym<text>($/) { make -> PDF::DOM::Item $_ { $_ ~~ Text} }

            method axis:sym<ancestor>($/)           { make &ancestor }
            method axis:sym<ancestor-or-self>($/)   { make &ancestor-or-self }
            method axis:sym<child>($/)              { make &child }
            method axis:sym<descendant>($/)         { make &descendant }
            method axis:sym<descendant-or-self>($/) { make &descendant-or-self }
            method axis:sym<following>($/)          { make &following }
            method axis:sym<following-sibling>($/)  { make &following-sibling }
            method axis:sym<parent>($/)             { make &parent }
            method axis:sym<preceding>($/)          { make &preceding }
            method axis:sym<preceding-sibling>($/)  { make &preceding-sibling }
            method axis:sym<self>($/)               { make &self }

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
            method term:sym<first>($/) { make -> { 1 } }
            method term:sym<last>($/)  { make -> { $*last } }
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
