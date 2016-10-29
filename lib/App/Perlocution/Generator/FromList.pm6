use v6;

use App::Perlocution;

class App::Perlocution::Generator::FromList
does App::Perlocution::Emitter {
    has @.items;

    method generate {
        for @.items { self.emit($_) }
        self.done;
    }
}
