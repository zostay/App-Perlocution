use v6;

use App::Perlocution;

class App::Perlocution::Processor::Lined
does App::Perlocution::Processor
does App::Perlocution::Builder {

    role Slurper does App::Perlocution::Filtered {
        has Str $.name;

        method slurp-up(@lines) { ... }

        method slurp-field(%item, @lines) {
            my $value = self.slurp-up(@lines);
            %item{ $.name } = self.apply-filter($value);
        }
    }
    class Single does Slurper {
        method slurp-up(@lines) { @lines.shift }
    }
    class Paragraph does Slurper {
        method slurp-up(@lines) {
            join "\n", gather {
                while @lines.elems > 0 && @lines[0] !~~ /\S/ {
                    @lines.shift;
                }
                while @lines.elems > 0 && @lines[0] ~~ /\S/ {
                    take @lines.shift;
                }
            }
        }
    }
    class Slurp does Slurper {
        method slurp-up(@lines) {
            my $keep = False;
            my @result = @lines.grep({ $keep ||= ?/\S/ });
            @lines = ();
            @result.join("\n");
        }
    }

    has Str $.slurp-field;
    has App::Perlocution::Processor::Lined::Slurper @.slurpers;

    method from-plan(::?CLASS:U: :$context, :@lines, :$slurp-field) {
        my @slurpers = gather for @lines -> %config {
            take self.build-from-plan(
                %config,
                :$context,
                :type-prefix(self.^name),
            );
        }

        self.new(:$context, :$slurp-field, :@slurpers);
    }

    method process(%item is copy) {
        my $slurp = %item{ $.slurp-field };
        my @lines = $slurp.lines;

        for @.slurpers -> $slurper {
            $slurper.slurp-field(%item, @lines);
        }

        self.emit(%item);
    }
}
