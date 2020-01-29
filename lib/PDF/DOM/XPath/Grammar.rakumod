grammar PDF::DOM::XPath::Grammar {
    # small neophytic XPath like expression evaluator

    rule TOP { <query>+ % '|' }

    rule query { [$<abs>='/']? <step>+ % '/' }

    proto rule step {*}
    rule step:sym<parent>    { '..' }
    rule step:sym<self>      { '.' }
    rule step:sym<regular>   { <axis> <node-test> <predicate>? }

    proto rule node-test {*}
    rule node-test:sym<tag>  { <tag=.ident> }
    rule node-test:sym<elem> { '*' }
    rule node-test:sym<node> { <sym> '(' ')' }
    rule node-test:sym<text> { <sym> '(' ')' }

    rule predicate           { '[' ~ ']' <expr(4)> }
    multi rule expr(0)       { <term> }
    multi rule expr($pred)   { <term=.expr($pred-1)> +% <q-op($pred-1)> }

    # expr operators - loosest to tightest
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
    rule term:sym<expr> { '(' ~ ')' <expr(4)> }

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
}