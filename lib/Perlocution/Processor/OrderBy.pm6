use v6;

use Perlocution;

class Perlocution::Processor::OrderBy
does Perlocution::Processor {
    has @.order-by;

    method from-plan(::?CLASS:U: :@order-by) {
        self.new(:@order-by);
    }

    method order-function {
        sub ($a, $b) {
            [||] do for @.order-by -> $field is copy {
                my $direction = $field ~~ s/^ '-'//;
                if !$direction {
                    ($a{$field}//'') cmp ($b{$field}//'')
                }
                else {
                    ($a{$field}//'') Rcmp ($b{$field}//'')
                }
            }
        }
    }

    method prepare-producer($helper, @things) {
        my $producer = $helper.merge(@things);
        $helper.sort($producer, self.order-function);
    }

    method process($item) {
        self.emit($item);
    }
}
