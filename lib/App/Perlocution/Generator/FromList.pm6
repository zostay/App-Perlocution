use v6;

use App::Perlocution;

class App::Perlocution::Generator::FromList
does App::Perlocution::Generator {
    has @.items;

    method from-plan(::?CLASS:U: :@items) {
        self.new(:@items);
    }

    method generate {
        for @.items { self.emit($_) }
        self.done;
    }
}
