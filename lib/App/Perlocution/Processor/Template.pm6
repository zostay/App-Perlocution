use v6;

use App::Perlocution;

class App::Perlocution::Processor::Template
does App::Perlocution::Processor
does App::Perlocution::Builder {
    use Template::Anti :ALL;

    multi get-anti-format-object('simple') {
        class {
            method parse($source) {
                class {
                    has $.source;

                    method set($name, $value) {
                        $!source ~~ s:global/ '$' $name >> /$value/;
                    }

                    method Str { $!source }
                }.new(:$source);
            }
        }
    }

    class Simple {
        has Str $.name;
        has &.render;

        method from-plan(::?CLASS:U: :$name, :$template) {
            sub simple-process($dom, %item) {
                for %item.kv -> $key, $value {
                    $dom.set($key, $value);
                }
            }

            self.new(
                :$name,
                :$template,
                render => anti-template(&simple-process,
                    :source($template),
                    :format<simple>,
                ),
            );
        }

        method template(%item) {
            %item{ $.name } = &.render.(%item);
        }
    }

    class Anti does App::Perlocution::Builder {
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
