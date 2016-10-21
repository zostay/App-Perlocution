use v6;

class App::Perlocution::Processor::SpurtFiles
does App::Perlocution::Process {
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
        $file.spurt($content);

        emit %item;
    }
}
