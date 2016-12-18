use v6;

use Perlocution;

class Perlocution::Generator::FromList
does Perlocution::Generator {
    has @.items;

    method from-plan(::?CLASS:U: :@items) {
        self.new(:@items);
    }

    method generate {
        for @.items { self.emit($_) }
        self.done;
    }
}
