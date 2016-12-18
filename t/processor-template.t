use v6;

use Test;
use Perlocution;

my $plan = load-plan({
    processors => {
        template => {
            type => 'Template',
            templates => [
                {
                    name     => "output-content",
                    type     => "Anti",
                    template => "tests.main",
                    include  => [ "t/view/lib" ],
                    path     => [ "t/view/originals" ],
                    views    => {
                        tests => {
                            type => "MyApp::Templates",
                        },
                    },
                },
                {
                    name => "output-filename",
                    type => "Simple",
                    template => '$id.html',
                },
            ],
        },
    },
    generators => {
        input => {
            type => 'FromList',
            items => [
                {
                    id => 'one',
                    title => 'One',
                    meta => 'Author: Bob',
                    body => 'Blah Blah',
                },
                {
                    id => 'two',
                    title => 'Two',
                    meta => "Author: Bob\nDate: Today",
                    body => "Blah\n\nBlah\n\nBlah",
                },
                {
                    id => 'three',
                    title => 'Three',
                    meta => "Author: Fred",
                    body => "Blah Blah\nBlah\n\nBlah",
                },
            ],
        },
    },
    flow => {
        template => [ 'generator:input' ],
    },
});

$plan.execute;

my @items = |$plan.context.processor('template').Queue.list;
is-deeply @items, [
    {
        id => 'one',
        title => 'One',
        meta => 'Author: Bob',
        body => 'Blah Blah',
        output-filename => 'one.html',
        output-content => q:to/END_OF_ONE/,
        <!DOCTYPE html>
        <html>
            <head>
                <title>One</title>
            </head>
            <body>
                <h1>One</h1>

                <p>Blah Blah</p>
            </body>
        </html>
        END_OF_ONE
    },
    {
        id => 'two',
        title => 'Two',
        meta => "Author: Bob\nDate: Today",
        body => "Blah\n\nBlah\n\nBlah",
        output-filename => 'two.html',
        output-content => q:to/END_OF_TWO/,
        <!DOCTYPE html>
        <html>
            <head>
                <title>Two</title>
            </head>
            <body>
                <h1>Two</h1>

                <p>Blah

        Blah

        Blah</p>
            </body>
        </html>
        END_OF_TWO
    },
    {
        id => 'three',
        title => 'Three',
        meta => "Author: Fred",
        body => "Blah Blah\nBlah\n\nBlah",
        output-filename => 'three.html',
        output-content => q:to/END_OF_THREE/,
        <!DOCTYPE html>
        <html>
            <head>
                <title>Three</title>
            </head>
            <body>
                <h1>Three</h1>

                <p>Blah Blah
        Blah

        Blah</p>
            </body>
        </html>
        END_OF_THREE
    },
], 'template processor works';

done-testing;
