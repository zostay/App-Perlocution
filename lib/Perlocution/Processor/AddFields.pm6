use v6;

use Perlocution;

class Perlocution::Processor::AddFields
does Perlocution::Processor {
    has %.fields;

    method from-plan(::?CLASS:U: :%fields) {
        self.new(:%fields);
    }

    method process(%item is copy) {
        %item = |%item, |%!fields;
        self.emit(%item);
    }
}
