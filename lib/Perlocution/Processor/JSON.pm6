use v6;

use Perlocution;
use JSON::Tiny;

class Perlocution::Processor::JSON
does Perlocution::Processor {
    has $.name;
    has @.fields;

    method from-plan(::?CLASS:U: :$context, :$name, :@fields) {
        self.new(:$name, :@fields);
    }

    method process(%item is copy) {
        my %obj;
        if @!fields {
            %obj = %item{ @!fields }:kv;
        }
        else {
            %obj = %item;
        }

        %item{ $!name } = to-json(%obj);
        self.emit(%item);
    }
}
