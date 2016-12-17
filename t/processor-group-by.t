use v6;

use Test;
use App::Perlocution;

subtest 'group by category', {
    my $plan = load-plan({
        generators => {
            from-list => {
                type => 'FromList',
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
            },
        },
        processors => {
            group-by => {
                type => 'GroupBy',
                items => 'items',
                group-by => [
                    {
                        from => 'category',
                        name => 'category',
                    },
                ],
            },
        },
        flow => {
            group-by => [ 'generator:from-list' ],
        },
    });

    $plan.execute;

    my @items = |$plan.context.processor('group-by').Queue.list;
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

subtest 'group by tags', {
    my $plan = load-plan({
        generators => {
            from-list => {
                type => 'FromList',
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
            },
        },
        processors => {
            group-by => {
                type => 'GroupBy',
                items => 'entries',
                group-by => [
                    {
                        from => 'tags',
                        name => 'tag',
                    },
                ],
            },
        },
        flow => {
            group-by => [ 'generator:from-list' ],
        },
    });

    $plan.execute;

    my @items = |$plan.context.processor('group-by').Queue.list;
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

subtest 'group by all', {
    my $plan = load-plan({
        generators => {
            from-list => {
                type => 'FromList',
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
            },
        },
        processors => {
            group-by => {
                type => 'GroupBy',
                items => 'things',
            },
        },
        flow => {
            group-by => [ 'generator:from-list' ],
        },
    });

    $plan.execute;

    my @items = |$plan.context.processor('group-by').Queue.list;
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

subtest 'group by multiple fields', {
    my $plan = load-plan({
        generators => {
            from-list => {
                type => 'FromList',
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
            },
        },
        processors => {
            group-by => {
                type => 'GroupBy',
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
            },
        },
        flow => {
            group-by => [ 'generator:from-list' ],
        },
    });

    $plan.execute;

    my @items = |$plan.context.processor('group-by').Queue.list;
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

done-testing;
