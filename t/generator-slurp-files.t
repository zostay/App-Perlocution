use v6;

use Test;
use App::Perlocution;

my $plan = load-plan({
    generators => {
        slurp-files => {
            type => 'SlurpFiles',
            meta  => {
                basename => {
                    name   => 'id',
                    filter => [
                        {
                            function => 'clip-end',
                            from     => '.',
                        },
                    ],
                },
                slurp => {
                    name => 'content',
                },
            },
            files => [ 't/files/*' ],
        },
    },
});

$plan.execute;
my @files = |$plan.context.generator('slurp-files')\
    .Queue.list.sort(*.<id> cmp *.<id>);

is-deeply @files, [
    {
        id => 'one',
        content => "# One\n\nTest one.\n",
    },
    {
        id => 'three',
        content => "# Three\n\nTest three.\n",
    },
    {
        id => 'two',
        content => "# Two\n\nTest two.\n",
    },
], 'found the expected files';

done-testing;
