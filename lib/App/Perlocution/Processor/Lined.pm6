use v6;

class App::Perlocution::Processor::Lined
does App::Perlocution::Processor
does App::Perloction::Builder {

    role Slurper does App::Perlocution::Filtered {
        has Str $.name;
        has @.filter;

        method slurp-up(@lines is rw) { ... }

        method slurp-field(%item is rw, @lines is rw) {
            my $value = self.slurp-up(@lines);
            %item{ $.name } = self.apply-filter($value, @.filter);
        }
    }
    class Single does Slurper {
        method slurp-up(@lines is rw) { @lines.shift }
    }
    class Paragraph does Slurper {
        method slurp-up(@lines is rw) {
            [~] gather do {
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
        method slurp-up(@lines is rw) {
            my @result = @lines;
            @lines = ();
            [~] @result;
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
