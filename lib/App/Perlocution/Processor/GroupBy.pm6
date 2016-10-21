use v6;

class App::Perlocution::Processor::GroupBy does App::Perlocution::Processor {
    has @.group-by;
    has @.order-by;

    method order-function {
        sub ($a, $b) {
            [||] do for @.order-by -> $field {
                my $direction = $field ~~ s/^ '-'//;
                if !$direction {
                    $a{$field} cmp $b{$field}
                }
                else {
                    $a{$field} Rcmp $b{$field}
                }
            }
        }
    }

    method prepare-producer(@supplies) {
        my $supply = Supply.merge(@supplies);
        $supply.reduce({ |$^a, $^b });
    }

    method process-item-group-by(:%buckets is rw, :%item is copy, :@group-by) {
        my ($name, $from) = @group-by[0]<name from>;

        my $value = %item{ $from };
        my @values = $value ~~ Iterable ?? |$value !! $value;

        for @values -> $value {
            if @group-by.elems > 1 {
                %buckets{ $value } //= %();
                %buckets{ $value } = self.process-item-group-by(
                    buckets  => %buckets{ $value },
                    item     => %item,
                    group-by => @group-by[1..*],
                );
            }
            else {
                %buckets{ $value } //= [];
                %buckets{ $value }.push: %item;

                # TODO SUPER INEFFICIENT, but easy to implement
                %buckets{ $value } .= sort(self.order-function);
            }
        }
    }

    method process(@item) {
        my %buckets;

        for @item -> %item is copy {
            self.process-item-group-by(:%buckets, :%item, :@group-by);
        }

        my @list = %buckets.values;
        for @list -> $stuff {
            given $stuff {
                when Hash { append @list, $stuff.values }
                default   {
                    for |$stuff -> $v {
                        self.emit($v);
                    }
                }
            }
        }
    }
}
