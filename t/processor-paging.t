use v6;

use Test;
use App::Perlocution::Generator::FromList;
use App::Perlocution::Processor::Paging;

my $context = App::Perlocution::Context.new;

{
    my $proc = App::Perlocution::Processor::Paging.from-plan(
        previous-name => 'prev',
        next-name     => 'next',
        page-name     => 'page',
        page-limit    => 3,
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            { :id<a> },
            { :id<b> },
            { :id<c> },

            { :id<d> },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    my $a := { :id<a>, :page(1) };
    my $b := { :id<b>, :page(1) }; $a<next> := $b; $b<prev> := $a;
    my $c := { :id<c>, :page(1) }; $b<next> := $c; $c<prev> := $b;
    my $d := { :id<d>, :page(2) }; $c<next> := $d; $d<prev> := $c;

    is-deeply @items, [ $a, $b, $c, $d ], "paging works";
}

{
    my $proc = App::Perlocution::Processor::Paging.from-plan(
        previous-name => 'prev',
        next-name     => 'next',
        page-name     => 'page',
        page-limit    => 3,
        min-per-page  => 2,
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            { :id<a> },
            { :id<b> },
            { :id<c> },

            { :id<d> },
            { :id<e> },
            { :id<f> },

            { :id<g> },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    my $a := { :id<a>, :page(1) };
    my $b := { :id<b>, :page(1) }; $a<next> := $b; $b<prev> := $a;
    my $c := { :id<c>, :page(1) }; $b<next> := $c; $c<prev> := $b;
    my $d := { :id<d>, :page(2) }; $c<next> := $d; $d<prev> := $c;
    my $e := { :id<e>, :page(2) }; $d<next> := $e; $e<prev> := $d;
    my $f := { :id<f>, :page(2) }; $e<next> := $f; $f<prev> := $e;
    my $g := { :id<g>, :page(2) }; $f<next> := $g; $g<prev> := $f;

    is-deeply @items, [ $a, $b, $c, $d, $e, $f, $g ], "min per page avoids break";
}

{
    my $proc = App::Perlocution::Processor::Paging.from-plan(
        previous-name => 'prev',
        next-name     => 'next',
        page-name     => 'page',
        page-limit    => 3,
        min-per-page  => 2,
    );

    my $gen = App::Perlocution::Generator::FromList.new(
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
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    my $a := { :id<a>, :page(1) };
    my $b := { :id<b>, :page(1) }; $a<next> := $b; $b<prev> := $a;
    my $c := { :id<c>, :page(1) }; $b<next> := $c; $c<prev> := $b;
    my $d := { :id<d>, :page(2) }; $c<next> := $d; $d<prev> := $c;
    my $e := { :id<e>, :page(2) }; $d<next> := $e; $e<prev> := $d;
    my $f := { :id<f>, :page(2) }; $e<next> := $f; $f<prev> := $e;
    my $g := { :id<g>, :page(3) }; $f<next> := $g; $g<prev> := $f;
    my $h := { :id<h>, :page(3) }; $g<next> := $h; $h<prev> := $g;

    is-deeply @items, [ $a, $b, $c, $d, $e, $f, $g, $h ], "min per page allows break";
}
done-testing;
