use v6;

use Test;
use App::Perlocution;
use App::Perlocution::Processor::Lined;

my $context = App::Perlocution::Context.new;

my $proc = App::Perlocution::Processor::Lined.from-plan(
    context     => $context,
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
);

my $gen = class :: does App::Perlocution::Emitter {
    has @.items;

    method generate {
        for @.items { self.emit($_) }
        self.done;
    }
}.new(
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
);

$proc.join([ $gen ]);
my $files = $proc.Supply;
start { $gen.generate }

my @files = |$files.list;
is-deeply @files, [
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
