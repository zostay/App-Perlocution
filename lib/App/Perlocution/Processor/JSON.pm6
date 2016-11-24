use v6;

use App::Perlocution;
use JSON::Tiny;

class App::Perlocution::Processor::JSON
does App::Perlocution::Processor {
    has $.name;
    has @.fields;

    method from-plan(::?CLASS:U: :$context, :$name, :@fields) {
        self.new(:$name, :@fields);
    }

    method process(%item is copy) {
        my %obj;
        if @!fields {
            %obj{ @!fields } = %item{ @!fields };
        }
        else {
            %obj = %item;
        }

        %item{ $!name } = to-json(%obj);
        self.emit(%item);
    }
}
