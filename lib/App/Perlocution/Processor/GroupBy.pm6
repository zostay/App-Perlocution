use v6;

use App::Perlocution;

class App::Perlocution::Processor::GroupBy does App::Perlocution::Processor {
    has $.items;
    has @.group-by;

    has %!bucket-order{Capture};
    has %!buckets{Capture};

    method from-plan(::?CLASS:U: :$items, :@group-by) {
        die "items is a required setting for the GroupBy processor" without $items;
        self.new(:$items, :@group-by);
    }

    method done {
        for %!bucket-order.sort(*.value cmp *.value)».key -> $key {
            self.emit(%!buckets{ $key });
        }
        $!feed.done;
    }

    method process(%item) {
        # Special case: group all
        if not @!group-by {
            %!bucket-order{\()} = 1;
            %!buckets{\()}{ $!items } //= [];
            %!buckets{\()}{ $!items }.push: %item;
            return;
        }

        my @key-order = @!group-by.map({ .<name> });
        my @metas = gather for @!group-by -> %grouping {
            my ($from, $name) := %grouping<from name>;
            my @values = do given %item{ $from } {
                when Iterable { |$_ }
                when so .defined { $_ }
                default { next }
            }

            next unless @values > 0;

            take @values.map(-> $value { $name => $value }).Array;
        }

        return unless @metas > 0;

        my @crossed-metas = |(@metas > 1 ?? [X] @metas !! @metas[0]);

        for @crossed-metas -> $expanded-meta {
            my %meta = $expanded-meta;
            my $key := \(|%meta{@key-order});
            %!bucket-order{ $key } //= %!bucket-order.elems + 1;
            my %bucket := %!buckets{ $key } //= %meta;
            %bucket{ $!items } //= [];
            %bucket{ $!items }.push: %item;
        }
    }
}
