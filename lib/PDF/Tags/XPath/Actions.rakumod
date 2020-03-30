class PDF::Tags::XPath::Actions {

    use PDF::Tags::Elem;
    use PDF::Tags::Node;
    use PDF::Tags::Mark;
    use PDF::Tags::ObjRef;
    use PDF::Tags::Text;
    use PDF::Tags::XPath::Axis;

    our constant Expression = Code;
    constant Elem      = PDF::Tags::Elem;
    constant Mark      = PDF::Tags::Mark;
    constant Node      = PDF::Tags::Node;
    constant ObjectRef = PDF::Tags::ObjRef;
    constant Text      = PDF::Tags::Text;

    method TOP($/) {
        my @query = @<query>>>.ast;

        make  -> PDF::Tags::Node:D $ref {
            if @query == 1 {
                (@query[0])($ref);
            }
            else {
                my @union;
                @union.append: ($_)($ref)
                    for @query;
                @union.unique;
            }
        }
    }

    method query($/) {
        make -> PDF::Tags::Node:D $ref is copy {
            $ref .= root() if $<abs>;
            my @set = ($ref,);
            @set = (.ast)(@set).unique
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
            my @step;
            for @set {
                my @group = &axis($_).grep(&node-test);
                @group = ($_)(@group) with &predicate;
                @step.append: @group;
            }
            @step;
        }
    }

    method predicate($/) {
        make -> @set {
            my &expr = $<expr>.ast;
            my $*position = 0;
            my $*last = +@set;
            @set = gather {
                for @set {
                    ++$*position;
                    my $v := &expr();
                    take $_ if ($v ~~ Bool && $v)
                       || ($v ~~ Int &&  $v == $*position);
                }
            }
        }
    }

    method node-test:sym<tag>($/) {
        my $name := ~$<tag>;
        make -> Node $_ { .name eq $name }
    }
    method node-test:sym<elem>($/)   { make -> Node $_ { $_ ~~ Elem} }
    method node-test:sym<node>($/)   { make -> Node $_ { True } }
    method node-test:sym<text>($/)   { make -> Node $_ { $_ ~~ Text} }
    method node-test:sym<object-ref>($/) { make -> Node $_ { $_ ~~ ObjectRef} }
    method node-test:sym<mark>($/)   { make -> Node $_ { $_ ~~ Mark} }

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
    method expr($/) {
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
    method term:sym<expr>($/) {
        make $<expr>.ast;
    }
}
