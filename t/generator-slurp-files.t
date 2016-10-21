use v6;

use Test;
use App::Perlocution::Generator::SlurpFiles;

my $context = App::Perlocution::Context.new;

my $gen = App::Perlocution::Generator::SlurpFiles.from-plan(
    context => $context,
    meta    => {
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
);


my $files = $gen.Supply.sort(*.<id> cmp *.<id>);
start { $gen.generate }

my @files = |$files.list;
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
