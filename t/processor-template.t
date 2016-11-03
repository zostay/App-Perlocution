use v6;

use Test;
use App::Perlocution::Generator::FromList;
use App::Perlocution::Processor::Template;

my $context = App::Perlocution::Context.new;

my $proc = App::Perlocution::Processor::Template.from-plan(
    context   => $context,
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
);

my $gen = App::Perlocution::Generator::FromList.new(
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
);

$proc.join([ $gen ]);
my $items = $proc.Supply;
start { $gen.generate }

my @items = |$items.list;
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
