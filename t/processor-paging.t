use v6;

use Test;
use App::Perlocution;

my $plan = load-plan({
    processors => {
        paging-next-prev => {
            type => 'Paging',
            previous-name => 'prev',
            next-name     => 'next',
        },
        paging-page-next-prev => {
            type => 'Paging',
            previous-name => 'prev',
            next-name     => 'next',
            page-name     => 'page',
            page-limit    => 3,
        },
        paging-min-prevents-break => {
            type => 'Paging',
            previous-name => 'prev',
            next-name     => 'next',
            page-name     => 'page',
            page-limit    => 3,
            min-per-page  => 2,
        },
        paging-min-allows-break => {
            type => 'Paging',
            previous-name => 'prev',
            next-name     => 'next',
            page-name     => 'page',
            page-limit    => 3,
            min-per-page  => 2,
        },
    },
    generators => {
        short-input => {
            type => 'FromList',
            items => [
                { :id<a> },
                { :id<b> },
                { :id<c> },

                { :id<d> },
            ],
        },
        medium-input => {
            type => 'FromList',
            items => [
                { :id<a> },
                { :id<b> },
                { :id<c> },

                { :id<d> },
                { :id<e> },
                { :id<f> },

                { :id<g> },
            ],
        },
        long-input => {
            type => 'FromList',
            items => [
                { :id<a> },
                { :id<b> },
                { :id<c> },

                { :id<d> },
                { :id<e> },
                { :id<f> },

                { :id<g> },
                { :id<h> },
            ],
        },
    },
    flow => {
        paging-next-prev => [ 'generator:short-input' ],
        paging-page-next-prev => [ 'generator:short-input' ],
        paging-min-prevents-break => [ 'generator:medium-input' ],
        paging-min-allows-break => [ 'generator:long-input' ],
    },
});

$plan.execute;

subtest 'next prev links are good' => {
    my @items = |$plan.context.processor('paging-next-prev').Queue.list;

    is @items[0]<id>, 'a', 'item a good';
    is @items[0]<next><id>, 'b', 'item a->next is good';
    is @items[1]<id>, 'b', 'item b good';
    is @items[1]<next><id>, 'c', 'item b->next is good';
    is @items[1]<prev><id>, 'a', 'item b->prev is good';
    is @items[2]<id>, 'c', 'item c good';
    is @items[2]<next><id>, 'd', 'item c->next is good';
    is @items[2]<prev><id>, 'b', 'item c->prev is good';
    is @items[3]<id>, 'd', 'item d good';
    is @items[3]<prev><id>, 'c', 'item d->prev is good';
}

subtest 'next prev links are good with paging' => {
    my @items = |$plan.context.processor('paging-page-next-prev').Queue.list;

    is @items[0]<id>, 'a', 'item a good';
    is @items[0]<page>, 1, 'item a page good';
    is @items[0]<next><id>, 'b', 'item a->next is good';
    is @items[1]<id>, 'b', 'item b good';
    is @items[1]<page>, 1, 'item b page good';
    is @items[1]<next><id>, 'c', 'item b->next is good';
    is @items[1]<prev><id>, 'a', 'item b->prev is good';
    is @items[2]<id>, 'c', 'item c good';
    is @items[2]<page>, 1, 'item c page good';
    is @items[2]<next><id>, 'd', 'item c->next is good';
    is @items[2]<prev><id>, 'b', 'item c->prev is good';
    is @items[3]<id>, 'd', 'item d good';
    is @items[3]<page>, 2, 'item d page good';
    is @items[3]<prev><id>, 'c', 'item d->prev is good';
}

subtest 'min-per-page prevents break' => {
    my @items = |$plan.context.processor('paging-min-prevents-break').Queue.list;

    is @items[0]<page>, 1, 'a is 1';
    is @items[1]<page>, 1, 'b is 1';
    is @items[2]<page>, 1, 'c is 1';
    is @items[3]<page>, 2, 'd is 2';
    is @items[4]<page>, 2, 'e is 2';
    is @items[5]<page>, 2, 'f is 2';
    is @items[6]<page>, 2, 'g is 2';
}

subtest 'min-per-page allows break' => {
    my @items = |$plan.context.processor('paging-min-allows-break').Queue.list;

    is @items[0]<page>, 1, 'a is 1';
    is @items[1]<page>, 1, 'b is 1';
    is @items[2]<page>, 1, 'c is 1';
    is @items[3]<page>, 2, 'd is 2';
    is @items[4]<page>, 2, 'e is 2';
    is @items[5]<page>, 2, 'f is 2';
    is @items[6]<page>, 3, 'g is 3';
    is @items[7]<page>, 3, 'h is 3';
}

done-testing;
