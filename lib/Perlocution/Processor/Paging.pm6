use v6;

use Perlocution;

class Perlocution::Processor::Paging
does Perlocution::Processor {
    has Str $.previous-name;
    has Str $.next-name;
    has Str $.page-name;
    has Int $.page-limit;
    has Int $.minimum-per-page = 1;

    has Int $!page-number = 0;
    has Int $!page-offset = 0;
    has @!previous-items;

    method from-plan(::?CLASS:U:
        Str :$previous-name, Str :$next-name, Str :$page-name,
        Int :$page-limit = 0,
        Int :min-per-page($minimum-per-page) = 1,
    ) {
        die "minimum-per-page must be no greater than page-limit"
            if $page-limit != 0 && $minimum-per-page > $page-limit;

        die "page-limit and page-name must both be specified"
            if $page-limit != 0 ^^ defined $page-name;

        self.new(
            :$previous-name, :$next-name, :$page-name,
            :$page-limit, :$minimum-per-page,
        );
    }

    multi method before-done() {
        self.emit($_) for @!previous-items;
    }

    method process(%item is copy) {
        with $!previous-name {
            %item{ $!previous-name } := @!previous-items[*-1]
                if @!previous-items;
        }

        with $!next-name {
            @!previous-items[*-1]{ $!next-name } := %item
                if @!previous-items;
        }

        @!previous-items[ @!previous-items.elems ] := %item;

        if $!page-name {
            $!page-offset++;

            # Wait to emit until a page is filled
            if $!page-offset > $!page-limit {
                $!page-offset = 1;
                self.emit(@!previous-items.shift)
                    while @!previous-items > 1;
            }

            # Keep items with the previous page until min-per-page items
            if $!page-offset == $!minimum-per-page {
                $!page-number++;
                for @!previous-items -> %item {
                    %item{ $!page-name } = $!page-number;
                }
            }
            else {
                %item{ $!page-name } = $!page-number max 1;
            }
        }

        # no page # so emission is simplified
        else {
            self.emit(@!previous-items.shift)
                if @!previous-items > 1;
        }
    }
}
