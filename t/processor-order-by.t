use v6;

use Test;
use App::Perlocution::Generator::FromList;
use App::Perlocution::Processor::OrderBy;

my $context = App::Perlocution::Context.new;

my $proc = App::Perlocution::Processor::OrderBy.from-plan(
    order-by => [ 'id', '-name', 'title' ],
);

my $gen = App::Perlocution::Generator::FromList.new(
    items => [
        { id => 'b', name => 'a', title => 'c', value => 1 },
        { id => 'a', name => 'b', title => 'a', value => 2 },
        { id => 'b', name => 'c', title => 'c', value => 3 },
        { id => 'b', name => 'a', title => 'd', value => 4 },
    ],
);

$proc.join([ $gen ]);
my $items = $proc.Supply;
start { $gen.generate }

my @items = |$items.list;
is-deeply @items, [
    { id => 'a', name => 'b', title => 'a', value => 2 },
    { id => 'b', name => 'c', title => 'c', value => 3 },
    { id => 'b', name => 'a', title => 'c', value => 1 },
    { id => 'b', name => 'a', title => 'd', value => 4 },
], 'sorted correctly';

done-testing;
