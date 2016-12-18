use v6;

use Test;
use Perlocution;

my $plan = load-plan({
    processors => {
        lined => {
            type => 'Lined',
            slurp-field => 'content',
            lines       => [
                {
                    name => 'title',
                    type => 'Single',
                },
                {
                    name => 'meta',
                    type => 'Paragraph',
                },
                {
                    name => 'body',
                    type => 'Slurp',
                },
            ],
        },
    },
    generators => {
        input => {
            type => 'FromList',
            items => [
                {
                    content => q:to/END_OF_ONE/,
                    One
                    Author: Bob

                    Blah Blah
                    END_OF_ONE
                },
                {
                    content => q:to/END_OF_TWO/,
                    Two
                    Author: Bob
                    Date: Today

                    Blah

                    Blah

                    Blah
                    END_OF_TWO
                },
                {
                    content => q:to/END_OF_THREE/,
                    Three
                    Author: Fred

                    Blah Blah
                    Blah

                    Blah
                    END_OF_THREE
                },
            ],
        },
    },
    flow => {
        lined => [ 'generator:input' ],
    },
});

$plan.execute;

my @items = |$plan.context.processor('lined').Queue.list;
is-deeply @items, [
        {
            title => 'One',
            meta => 'Author: Bob',
            body => 'Blah Blah',
            content => q:to/END_OF_ONE/,
            One
            Author: Bob

            Blah Blah
            END_OF_ONE
        },
        {
            title => 'Two',
            meta => "Author: Bob\nDate: Today",
            body => "Blah\n\nBlah\n\nBlah",
            content => q:to/END_OF_TWO/,
            Two
            Author: Bob
            Date: Today

            Blah

            Blah

            Blah
            END_OF_TWO
        },
        {
            title => 'Three',
            meta => "Author: Fred",
            body => "Blah Blah\nBlah\n\nBlah",
            content => q:to/END_OF_THREE/,
            Three
            Author: Fred

            Blah Blah
            Blah

            Blah
            END_OF_THREE
        },
], 'lined processing parses content nicely';

done-testing;
