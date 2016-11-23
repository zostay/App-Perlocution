unit module App::Perlocution::Filters;
use v6;

use Text::Markdown;

our sub fc($v, :$context) { $v.fc }
our sub tc($v, :$context) { $v.tc }
our sub lc($v, :$context) { $v.lc }
our sub uc($v, :$context) { $v.uc }
our sub tclc($v, :$context) { $v.tclc }

our sub split($v, :$context, :$by) { $v.split($by) }
our sub map($v, :$context, :@filter) {
    my @v = |$v;
    @v.map({
        $context.apply-filter($_, @filter);
    }).cache;
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

our sub subst($v, :$context, :$match, :$replacement, :$global) {
    $v.subst($match, $replacement, :$global);
}

our sub subst-re($v, :$context, :$match, :$replacement, :$global) {
    $v.subst(/<{$match}>/, $replacement, :$global);
}
