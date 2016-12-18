use v6;

use Test;
use App::Perlocution;
use JSON::Tiny;

my @input =
    { a => 1, b => 2 },
    { a => 3, b => 4, c => 5 },
    { a => 6, d => 7 },
    ;

my $plan = load-plan({
    generators => {
        from-list => {
            type => 'FromList',
            items => @input,
        },
    },
    processors => {
        with-fields => {
            type    => 'JSON',
            name    => 'json',
            fields  => <a b c>,
        },
        without-fields => {
            type    => 'JSON',
            name    => 'json',
        },
    },
    flow => {
        with-fields    => [ 'generator:from-list' ],
        without-fields => [ 'generator:from-list' ],
    },
});

$plan.execute;

subtest 'with fields' => {
    my @items = |$plan.context.processor('with-fields')\
        .Queue.list;

    my @expect = @input.map(-> %item {
        my %hash = %item<a b c>:kv;
        %( |%item, json => to-json(%hash) )
    });

    is-deeply @items, @expect, 'JSON limited to fields works';
}

subtest 'without fields' => {
    my @items = |$plan.context.processor('without-fields')\
        .Queue.list;

    my @expect = @input.map(-> %item {
        %( |%item, json => to-json(%item) )
    });

    is-deeply @items, @expect, 'JSON limited to fields works';
}

done-testing;
