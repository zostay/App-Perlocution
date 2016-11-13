use v6;

use App::Perlocution;

class App::Perlocution::Generator::SlurpFiles
does App::Perlocution::Generator {

    use IO::Glob;

    has %.meta;
    has IO::Glob @.globs;

    method from-plan(::?CLASS:U: :$context, :%meta, :@files) {
        my IO::Glob @globs = @files.map({ glob($_) });

        for %meta.kv -> $name, %p {
            %p<filter> = App::Perlocution::Filtered.from-plan(
                context => $context,
                filter  => %p<filter> // [],
            );
        }

        self.new(:@globs, :%meta);
    }

    method generate() {
        for flat @.globs.map({ .dir }) -> $file {
            next unless $file ~~ :f;

            self.debug("Reading %s", $file);

            my %file-item;
            for %.meta.kv -> $name, %p {
                my $filter = %p<filter>;
                my $become = %p<name>;

                %file-item{ $become } = $filter.apply-filter(
                    do given $name {
                        when 'basename' { $file.basename }
                        when 'slurp'    { $file.slurp }
                        default {
                            warn qq[there is no filename meta named "$name"];
                        }
                    }
                );
            }

            self.emit(%file-item);
        }

        self.done;
    }
}
