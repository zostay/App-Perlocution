use v6;

use Test;
use App::Perlocution;

my $plan = load-plan({
    processors => {
        order-by => {
            type => 'OrderBy',
            order-by => [ 'id', '-name', 'title' ],
        },
    },
    generators => {
        input => {
            type => 'FromList',
            items => [
                { id => 'b', name => 'a', title => 'c', value => 1 },
                { id => 'a', name => 'b', title => 'a', value => 2 },
                { id => 'b', name => 'c', title => 'c', value => 3 },
                { id => 'b', name => 'a', title => 'd', value => 4 },
            ],
        },
    },
    flow => {
        order-by => [ 'generator:input' ],
    },
});

$plan.execute;

my @items = |$plan.context.processor('order-by').Queue.list;

is-deeply @items, [
    { id => 'a', name => 'b', title => 'a', value => 2 },
    { id => 'b', name => 'c', title => 'c', value => 3 },
    { id => 'b', name => 'a', title => 'c', value => 1 },
    { id => 'b', name => 'a', title => 'd', value => 4 },
], 'sorted correctly';

done-testing;
