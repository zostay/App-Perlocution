unit module App::Perlocution::Filters;
use v6;

use Text::Markdown;

our sub split($v, :$context, :$by) { $v.split($by) }
our sub map($v, :$context, :@filter) {
    my @v = |$v;
    @v.map({
        $context.apply-filter($_, @filter);
    });
}
our sub trim($v, :$context) { $v.trim }
our sub markdown($v, :$context) { Text::Markdown.new($v).render }

our sub clip-end($v, :$context, :$from) {
    with $v.rindex($from) -> $index {
        $v.substr(0, $index);
    }
    else {
        $v
    }
}

our sub clip-start($v, :$context, :$to) {
    with $v.index($to) -> $index {
        $v.substr($index + 1);
    }
    else {
        $v
    }
}

our sub subst($v, :$match, :$replacement, :$global) {
    $v.subst($match, $replacement, :$global);
}

our sub subst-re($v, :$match, :$replacement, :$global) {
    $v.subst(/<{$match}>/, $replacement, :$global);
}
