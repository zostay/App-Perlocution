use v6;

class App::Perlocution::Processor::Paging
does App::Perlocution::Processor {
    has Str $.previous-name;
    has Str $.next-name;
    has Str $.page-name;
    has Int $.page-limit;
    has Int $.minimum-per-page = 1;

    has Int $!page-number = 1;
    has Int $!page-offset = 0;
    has @!previous-items;

    method from-plan(::?CLASS:U:
        Str :$previous-name, Str :$next-name, Str :$page-name,
        Int :$page-limit = 0 where * >= 0,
        Int :min-per-page($minimum-per-page) = 1 where * >= 1,
    ) {
        die "minimum-per-page must be no greater than page-limit"
            if $page-limit > 0 && $minimum-per-page > $page-limit;

        die "page-limit and page-name must both be specified"
            if $page-limit != 0 || defined $page-name;

        self.new(
            :$prevoius-name, :$next-name, $page-name,
            :$page-limit, :$minimum-per-page,
        );
    }

    method done() {
        self.emit($_) for @!previous-items;
        self.App::Perlocution::Emitter::done;
    }

    method process(%item is copy) {
        with $!previous-name {
            %item{ $!previous-name } := @!previous-items[*-1]
                if @!previous-items;
        }

        with $!next-name {
            @!previous-items[0]{ $!next-name } := %item
                if @!previous-items;
        }

        @!previous-items.push: %item;
        self.emit(@!previous-items.shift)
            if @!previous-items > 1;
    }
}
