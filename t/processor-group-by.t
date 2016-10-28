use v6;

use Test;
use App::Perlocution::Generator::FromList;
use App::Perlocution::Processor::GroupBy;

my $context = App::Perlocution::Context.new;

{
    my $proc = App::Perlocution::Processor::GroupBy.from-plan(
        items => 'items',
        group-by => [
            {
                from => 'category',
                name => 'category',
            },
        ],
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            {
                name => 'one',
                category => 'foo',
            },
            {
                name => 'two',
                category => 'bar',
            },
            {
                name => 'three',
                category => 'foo',
            },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    is-deeply @items, [
        {
            category => 'foo',
            items => [
                {
                    name => 'one',
                    category => 'foo',
                },
                {
                    name => 'three',
                    category => 'foo',
                },
            ],
        },
        {
            category => 'bar',
            items => [
                {
                    name => 'two',
                    category => 'bar',
                },
            ],
        },
    ], 'single field single item group by works';
}

{
    my $proc = App::Perlocution::Processor::GroupBy.from-plan(
        items => 'entries',
        group-by => [
            {
                from => 'tags',
                name => 'tag',
            },
        ],
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            {
                name => 'one',
                tags => [ 'foo', 'bar' ],
            },
            {
                name => 'two',
                tags => [ 'bar', 'baz' ],
            },
            {
                name => 'three',
                tags => [ 'foo' ],
            },
            {
                name => 'four',
                tags => [],
            },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    is-deeply @items, [
        {
            tag => 'foo',
            entries => [
                {
                    name => 'one',
                    tags => [ 'foo', 'bar' ],
                },
                {
                    name => 'three',
                    tags => [ 'foo' ],
                },
            ],
        },
        {
            tag => 'bar',
            entries => [
                {
                    name => 'one',
                    tags => [ 'foo', 'bar' ],
                },
                {
                    name => 'two',
                    tags => [ 'bar', 'baz' ],
                },
            ],
        },
        {
            tag => 'baz',
            entries => [
                {
                    name => 'two',
                    tags => [ 'bar', 'baz' ],
                },
            ]
        },
    ], 'single field multi item group by works';
}

{
    my $proc = App::Perlocution::Processor::GroupBy.from-plan(
        items => 'things',
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            {
                name => 'one',
                tags => [ 'foo', 'bar' ],
            },
            {
                name => 'two',
                tags => [ 'bar', 'baz' ],
            },
            {
                name => 'three',
                tags => [ 'foo' ],
            },
            {
                name => 'four',
                tags => [],
            },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    is-deeply @items, [
        {
            things => [
                {
                    name => 'one',
                    tags => [ 'foo', 'bar' ],
                },
                {
                    name => 'two',
                    tags => [ 'bar', 'baz' ],
                },
                {
                    name => 'three',
                    tags => [ 'foo' ],
                },
                {
                    name => 'four',
                    tags => [],
                },
            ],
        },
    ], 'no field group by works';
}

{
    my $proc = App::Perlocution::Processor::GroupBy.from-plan(
        items => 'items',
        group-by => [
            {
                name => 'category',
                from => 'category',
            },
            {
                name => 'tag',
                from => 'tags',
            },
        ],
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            {
                name => 'one',
                category => 'foo',
                tags => [ 'zizzle', 'zazzle' ],
            },
            {
                name => 'two',
                category => 'bar',
                tags => [ 'zazzle', 'nargle' ],
            },
            {
                name => 'three',
                category => 'foo',
                tags => [ 'zizzle' ],
            },
            {
                name => 'four',
                category => 'bar',
                tags => [],
            },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    is-deeply @items, [
        {
            category => 'foo',
            tag => 'zizzle',
            items => [
                {
                    name => 'one',
                    category => 'foo',
                    tags => [ 'zizzle', 'zazzle' ],
                },
                {
                    name => 'three',
                    category => 'foo',
                    tags => [ 'zizzle' ],
                },
            ],
        },
        {
            category => 'foo',
            tag => 'zazzle',
            items => [
                {
                    name => 'one',
                    category => 'foo',
                    tags => [ 'zizzle', 'zazzle' ],
                },
            ],
        },
        {
            category => 'bar',
            tag => 'zazzle',
            items => [
                {
                    name => 'two',
                    category => 'bar',
                    tags => [ 'zazzle', 'nargle' ],
                },
            ],
        },
        {
            category => 'bar',
            tag => 'nargle',
            items => [
                {
                    name => 'two',
                    category => 'bar',
                    tags => [ 'zazzle', 'nargle' ],
                },
            ],
        },
        {
            category => 'bar',
            items => [
                {
                    name => 'four',
                    category => 'bar',
                    tags => [],
                },
            ],
        },
    ], 'multi field mixed item group by works';
}

