use v6;

use Test;
use App::Perlocution::Generator::FromList;
use App::Perlocution::Processor::SpurtFiles;

my $context = App::Perlocution::Context.new;

my $rand-name = ('A'..'Z','a'..'z','0'..'9').flat.pick(10).join;
my $dir = $*TMPDIR.child($rand-name);
{
    ENTER { $dir.mkdir }

    my $proc = App::Perlocution::Processor::SpurtFiles.from-plan(
        context        => $context,
        directory      => ~$dir,
        filename-field => 'spurt-filename',
        spurt-field    => 'spurt-content',
    );

    my $gen = App::Perlocution::Generator::FromList.new(
        items => [
            {
                spurt-filename => 'one.txt',
                spurt-content  => 'One',
            },
            {
                spurt-filename => 'two.txt',
                spurt-content  => 'Two',
            },
            {
                spurt-filename => 'three.txt',
                spurt-content  => 'Three',
            },
        ],
    );

    $proc.join([ $gen ]);
    my $items = $proc.Supply;
    start { $gen.generate }

    my @items = |$items.list;
    for @items -> %item {
        ok $dir.child(%item<spurt-filename>) ~~ :f, "file %item<spurt-filename> exists";
        is $dir.child(%item<spurt-filename>).slurp, %item<spurt-content>, "file %item<spurt-filename> has correct contents";
    }

    LEAVE {
        for $dir.dir -> $file { $file.unlink }
        $dir.rmdir;
    }
}

done-testing;
