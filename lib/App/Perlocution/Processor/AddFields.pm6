use v6;

use App::Perlocution;

class App::Perlocution::Processor::AddFields
does App::Perlocution::Processor {
    has %.fields;

    method from-plan(::?CLASS:U: :%fields) {
        self.new(:%fields);
    }

    method process(%item is copy) {
        %item = |%item, |%!fields;
        self.emit(%item);
    }
}
