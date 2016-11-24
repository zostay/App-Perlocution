use v6;

use App::Perlocution;

class App::Perlocution::Processor::Filter
does App::Perlocution::Processor {
    has @.keep;
    has @.drop;

    method from-plan(::?CLASS:U: :$context, :@keep, :@drop) {
        self.new(:@keep, :@drop);
    }

    method process(%item is copy) {
        %item = %item{ @!keep } if @!keep;
        %item{ @!drop } :delete;
        self.emit(%item);
    }
}
