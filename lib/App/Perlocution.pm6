unit module App::Perlocution:ver<0.1>:auth<Sterling Hanenkamp (hanenkamp@cpan.org)>;
use v6;

use CompUnit::DynamicLib;
use JSON::Tiny;

class Context { ... }

role Builder {
    method !construct($type, Capture $c) {
        if $type.^find_method('from-plan') {
            $type.from-plan(|$c);
        }
        else {
            $type.new;
        }
    }

    multi method build-from-plan(%config, :$section, :$type-prefix!, Context :$context!, :@include) {
        my %plan = $context.plan;

        with $section {
            my $config = %config<config> :delete;
            with $config {
                %config =
                    |%plan{ $section }{ $config },
                    |%config;
            }
        }

        my $type-name = %config<type> :delete;
        my $class-name = do with $type-prefix {
            "{$type-prefix}::$type-name";
        }
        else {
            $type-name;
        }

        my $type;
        try {
            CATCH {
                when X::NoSuchSymbol {
                    require-from @include, $class-name;
                    $type = ::($class-name);
                }
            }

            $type = ::($class-name);
        }

        self!construct($type, \(:$context, |%config));
    }

    multi method build-from-plan(%config, :$section, :$type!, :$context!, :@include) {
        my %plan = $context.plan;

        with $section {
            my $config = %config<config> :delete;
            with $config {
                %config =
                    |%plan{ $section }{ $config },
                    |%config;
            }
        }

        self!construct($type, \(:$context, |%config));
    }
}

class Filter { ... }

role Filtered {
    also does Builder;

    has @.filter;

    method from-plan(::?CLASS:U: Context :$context, :@filter is copy, *%plan) {
        @filter.=map(-> %config {
            self.build-from-plan(
                %config,
                :$context,
                :type(Filter),
                :section<filters>,
            )
        });

        self.new(:@filter, |%plan);
    }

    method apply-filter(::?CLASS:D: $v is copy) {
        for @!filter -> $filter {
            $v = $filter.apply($v);
        }

        $v;
    }
}

role Emitter {
    has Supplier $!feed = Supplier::Preserving.new;

    method emit($item) { $!feed.emit($item) }
    method done() { $!feed.done }
    method quit($x) { $!feed.quit($x) }
    multi method Supply { $!feed.Supply }
}

role Component { ... }

role Generator {
    also does Component;
    also does Emitter;

    method generate() { ... }
}

role Processor {
    also does Component;
    also does Emitter;

    method prepare-producer(@supplies) {
        Supply.merge(@supplies)
    }

    multi method join(@sources) {
        return unless @sources;

        my Supply @supplies = @sources.map({ .Supply });
        my $producer = self.prepare-producer(@supplies);
        $producer.tap(
            -> $item {
                CATCH {
                    default { self.quit($_) }
                }

                self.process($item);
            },
            done => { self.done },
            quit => { self.quit($_) },
        );
    }

    method process($item) { ... }
}

class Context
does Builder {
    use App::Perlocution::Filters;

    has %.plan;
    has %.generators;
    has %.processors;
    has @.run;
    has %.filters =
            :&split, :&map, :&trim,# :&markdown,
            :&clip-end, :&clip-start,
        ;

    method processor($name) {
        die qq[no configuration for processor named "$name"]
            unless %!plan<processors>{ $name }:exists;

        %.processors{ $name } //= self.build-from-plan(
            %.plan<processors>{ $name },
            :context(self),
            :type-prefix<App::Perlocution::Processor>,
            :section<processors>
        );
    }

    method generator($name) {
        die qq[no configuration for generator named "$name"]
            unless %!plan<generators>{ $name }:exists;

        %.generators{ $name } //= self.build-from-plan(
            %.plan<generators>{ $name },
            :context(self),
            :type-prefix<App::Perlocution::Generator>,
            :section<generators>
        );
    }

    method source($name) {
        my ($type, $real-name) = $name.split(':', 2);
        my $obj = do given $type {
            when 'generator' { self.generator($real-name) }
            when 'processor' { self.processor($real-name) }
            default {
                die qq[unknown process type "$_"];
            }
        }
    }

    method from-plan(::?CLASS:U: *%plan) {
        my $self = self.new(:%plan);
        $self.init;
    }

    method init(::?CLASS:D:) {
        for %!plan<flow>.kv -> $processor-name, $source-names {
            my @source-names = |$source-names.list;
            my $processor = self.processor($processor-name);

            my Emitter @sources = @source-names.map(-> $name {
                self.source($name);
            });

            $processor.join(@sources);
        }

        @!run = (%!plan<run> // %!generators.keys).map({
            self.generator($^name);
        });

        self;
    }

    method run() {
        do for @!run -> $generator {
            start {
                CATCH {
                    default {
                        note "Failed during generation: $_";
                    }
                }

                $generator.generate;
            }
        }
    }

    method apply-filter($v, @filter) {
        # Ah, the power of punning
        my $filter = Filtered.from-plan(
            context => self,
            filter  => @filter,
        );

        $filter.apply-filter($v);
    }
}

role Component {
     method from-plan { ... }
}

class Filter
does Component
does Builder {
    has &.function;

    method from-plan(::?CLASS:U: :$context, :$function, |c) {
        with $context.filters{ $function } -> &f {
            if &f.cando: \(Any, :$context, |c) {
                self.new(
                    function => &f.assuming(:$context, |c),
                );
            }
            else {
                die qq[function configuration is incorrect for "$function"];
            }
        }
        else {
            die qq[there is no filter named "$function"];
        }
    }

    method apply($v) {
        &!function.($v);
    }
}

class Plan {
    has $.context;

    method execute() {
        await $!context.run;
    }
}

multi load-plan(Str $plan-text) is export {
    my %plan = from-json($plan-text);
    my $context = Context.from-plan(|%plan);
    Plan.new(:$context);
}

multi load-plan(IO::Path $plan-file) is export {
    load-plan($plan-file.slurp);
}

sub MAIN(Str :$plan-file = 'site.json') is export(:MAIN) {
    my $plan = load-plan($plan-file.IO);
    note "Plan loaded.";
    $plan.execute;
}
