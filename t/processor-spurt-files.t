use v6;

use Test;
use Perlocution;


my $rand-name = ('A'..'Z','a'..'z','0'..'9').flat.pick(10).join;
my $dir = $*TMPDIR.child($rand-name);

{
    ENTER { $dir.mkdir }

    my $plan = load-plan({
        processors => {
            spurt-files => {
                type => 'SpurtFiles',
                directory      => ~$dir,
                filename-field => 'spurt-filename',
                spurt-field    => 'spurt-content',
            },
        },
        generators => {
            input => {
                type => 'FromList',
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
            },
        },
        flow => {
            spurt-files => [ 'generator:input' ],
        },
    });

    $plan.execute;

    my @items = |$plan.context.processor('spurt-files').Queue.list;
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
