unit module App::Perlocution::Filters;
use v6;

#use Text::Markdown;

sub split($v, :$context, :$by) is export { $v.split($by) }
sub map(@v, :$context, :@filter) is export {
    @v.map({
        $context.apply-filter($_, @filter);
    });
}
sub trim($v, :$context) is export { $v.trim }
#sub markdown($v, :$context) { markdown($v) }

sub clip-end($v, :$context, :$from) is export {
    with $v.rindex($from) -> $index {
        $v.substr(0, $index);
    }
    else {
        $v
    }
}

sub clip-start($v, :$context, :$to) is export {
    with $v.index($to) -> $index {
        $v.substr($index + 1);
    }
    else {
        $v
    }
}
