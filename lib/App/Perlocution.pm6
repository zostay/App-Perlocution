unit module App::Perlocution;
use v6;

use CompUnit::DynamicLib;
use JSON::Tiny;

class Context { ... }

role Builder {
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

        $type.from-plan(:$context, |%config);
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

        $type.from-plan(:$context, |%config);
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
    has Supplier $!items = Supplier.new;

    method emit($item) { $!items.emit($item) }
    method done() { $!items.done }
    method quit($x) { $!items.quit($x) }
    multi method Supply { $!items.Supply }
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

    method process(%item) { ... }
}

class Context
does Builder {
    use App::Perlocution::Filters;
#    use Filtered;
#
    has %.plan;
#    has %.generators;
#    has %.processors;
    has %.filters =
            :&split, :&map, :&trim,# :&markdown,
            :&clip-end, :&clip-start,
        ;

#    method processor($name) {
#        %.processors{ $name } //= self.build-from-plan(
#            %.plan<processors>{ $name },
#            :context(self),
#            :type-prefix<App::Perlocution::Processor>,
#            :section<processors>
#        );
#    }
#
#    method generator($name) {
#        %.generators{ $name } //= self.build-from-plan(
#            %.plan<generators>{ $name },
#            :context(self),
#            :type-prefix<App::Perlocution::Generator>,
#            :section<generators>
#        );
#    }
#
#    method from-plan(::?CLASS:U: %plan) {
#        my $self = self.new(:%plan);
#        $self.init;
#    }
#
#    method init(::?CLASS:D:) {
#        for %plan<flow>.kv -> $processor-name, @source-names {
#            my $processor = self.processor($processor-name);
#
#            my Emitter @sources = @source-names.map(-> $name {
#                my ($type, $real-name) = $name.split(':', 2);
#                my $obj = do given $type {
#                    when 'generator' { self.generator($real-name) }
#                    when 'processor' { self.processor($real-name) }
#                    default {
#                        die qq[unknown process type "$_"];
#                    }
#                }
#            });
#
#            $processor.join(@sources);
#        }
#
#        self;
#    }
#
#    method apply-filter($v, @filter) {
#        # Ah, the power of punning
#        my $filter = Filtered.from-plan(
#            context => self,
#            filter  => @filter,
#        );
#
#        $filter.apply-filter($v);
#    }
}

role Component {
#     has Context $.context;
#
#     method from-plan(::?CLASS:U: *%config) {
#         self.new(|%config);
#     }
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

# class Plan {
#     has $.context;
#
#     method execute() {
#         for $.context.generators.values -> $generator {
#             start { $generator.generate }
#         }
#     }
# }
#
# sub load-plan(IO::Path $plan-file) is export {
#     my %plan = from-json($plan-file.slurp);
#     my $context = Context.from-plan(:%plan);
#     Plan.new(:$context);
# }
#
# sub MAIN(Str :$plan-file = 'site.json') is export(:MAIN) {
#     my $plan = load-plan($plan-file.IO);
#     note "Plan loaded.";
#     $plan.execute;
# }
