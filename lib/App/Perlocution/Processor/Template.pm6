use v6;

use App::Perlocution;

class App::Perlocution::Processor::Template
does App::Perlocution::Processor
does App::Perlocution::Builder {
    class Simple does App::Perlocution::Filtered {
        has Str $.name;
        has &.render;

        use Template::Anti :one-off;

        class SimpleFormat is Template::Anti::Format {
            method parse($source) {
                class {
                    has $.source;

                    method set($name, $value) {
                        $!source ~~ s:global/ '$' $name >> /$value/;
                    }

                    method Str { $!source }
                }.new(:$source);
            }

            method prepare-original($master) {
                $master.clone;
            }

            method render($final) { $final.source }
        }

        sub simple-process($dom, %item) {
            for %item.kv -> $key, $value {
                $dom.set($key, $value);
            }
        }

        method from-plan(::?CLASS:U: :$name, :$template) {
            self.new(
                :$name,
                :$template,
                render => anti-template(&simple-process,
                    :source($template),
                    :format(SimpleFormat),
                ),
            );
        }

        method template(%item) {
            %item{ $.name } = &.render.(%item);
        }
    }

    class Anti does App::Perlocution::Filtered {
        use Template::Anti;

        has Str $.name;
        has Str $.anti;
        has Str @.include;

        has Template::Anti::Library $.library;

        method from-plan(::CLASS:U:
            :$context,
            :$name,
            :$template,
            :@include,
            :%views is copy,
            :@path,
        ) {
            %views = %views.kv.map(-> $key, %view-config {
                $key => self.build-from-plan(
                    %view-config,
                    :$context,
                    :type-prefix(Nil),
                    :@include,
                );
            });

            my $library = Template::Anti::Library.new(
                :@path,
                :%views,
            );

            my $anti = $template;
            self.new(:$name, :$anti, :$library);
        }

        method template(%item) {
            %item{ $.name } = $.library.process($.anti, %item);
        }
    }

    has @.templates;

    method from-plan(::?CLASS:U: :$context, :@templates) {
        my @setup-templates = @templates.map(-> %tmpl-conf {
            self.build-from-plan(
                %tmpl-conf,
                :$context,
                :type-prefix(self.^name),
                :section<templates>,
            );
        });

        self.new(:$context, templates => @setup-templates);
    }

    method process(%item is copy) {
        for @.templates -> $template {
            $template.template(%item);
        }

        self.emit(%item);
    }
}
