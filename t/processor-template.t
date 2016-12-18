use v6;

use Test;
use Perlocution;

my $plan = load-plan({
    templates => {
        template-anti => {
            include  => [ "t/view/lib" ],
            path     => [ "t/view/originals" ],
            views    => {
                tests => {
                    type => "MyApp::Templates",
                },
            },
        },
    },
    processors => {
        template => {
            type => 'Template',
            templates => [
                {
                    name => "keys-values",
                    type => 'Anti',
                    template => 'tests.list',
                    config   => 'template-anti',
                },
                {
                    name     => "output-content",
                    type     => "Anti",
                    template => "tests.main",
                    config   => 'template-anti',
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
        keys-values => q:to/END_OF_KEYS_VALUES_ONE/,
        <table>
            <thead>
                <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
                <tr><td class="key">body</td><td class="value">Blah Blah</td></tr><tr><td class="key">id</td><td class="value">one</td></tr><tr><td class="key">meta</td><td class="value">Author: Bob</td></tr><tr><td class="key">title</td><td class="value">One</td></tr>
            </tbody>
        </table>
        END_OF_KEYS_VALUES_ONE
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
        keys-values => q:to/END_OF_KEYS_VALUES_TWO/,
        <table>
            <thead>
                <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
                <tr><td class="key">body</td><td class="value">Blah

        Blah

        Blah</td></tr><tr><td class="key">id</td><td class="value">two</td></tr><tr><td class="key">meta</td><td class="value">Author: Bob
        Date: Today</td></tr><tr><td class="key">title</td><td class="value">Two</td></tr>
            </tbody>
        </table>
        END_OF_KEYS_VALUES_TWO
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
        keys-values => q:to/END_OF_KEYS_VALUES_THREE/,
        <table>
            <thead>
                <tr><th>Key</th><th>Value</th></tr>
            </thead>
            <tbody>
                <tr><td class="key">body</td><td class="value">Blah Blah
        Blah

        Blah</td></tr><tr><td class="key">id</td><td class="value">three</td></tr><tr><td class="key">meta</td><td class="value">Author: Fred</td></tr><tr><td class="key">title</td><td class="value">Three</td></tr>
            </tbody>
        </table>
        END_OF_KEYS_VALUES_THREE
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
