use v6;

use Perlocution;

class Perlocution::Processor::Template
does Perlocution::Processor
does Perlocution::Builder {
    class Simple does Perlocution::Filtered {
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

        method from-plan(::?CLASS:U: :$context, :$name, :$template, *%plan) {
            self.Perlocution::Filtered::from-plan(
                :$context,
                :$name,
                :$template,
                render => anti-template(&simple-process,
                    :source($template),
                    :format(SimpleFormat),
                ),
                |%plan,
            );
        }

        method template(%item) {
            %item{ $.name } = self.apply-filter(
                &.render.(%item)
            );
        }
    }

    class Anti does Perlocution::Filtered {
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
            *%plan,
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
            self.Perlocution::Filtered::from-plan(
                :$context, :$name, :$anti, :$library,
                |%plan,
            );
        }

        method template(%item) {
            %item{ $.name } = self.apply-filter(
                $.library.process($.anti, |%item)
            );
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
