use v6;

use App::Perlocution;

class App::Perlocution::Processor::SpurtFiles
does App::Perlocution::Processor {
    has IO::Path $.directory;
    has Str $.filename-field;
    has Str $.spurt-field;

    method from-plan(::?CLASS:U: :$directory is copy, *%config) {
        $directory.=IO;
        self.new(:$directory, |%config);
    }

    method process(%item) {
        my $filename = %item{ $.filename-field };
        my $content  = %item{ $.spurt-field };

        return unless $filename.defined;
        return unless $content.defined;

        my $file = $.directory.child($filename);
        self.debug("Writing %s", $file);

        $file.spurt($content);

        self.emit(%item);
    }
}
