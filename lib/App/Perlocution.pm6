unit module App::Perlocution:ver<0.3>:auth<Sterling Hanenkamp (hanenkamp@cpan.org)>;
use v6;

use CompUnit::DynamicLib;
use JSON::Tiny;

use App::Perlocution::Filters;

class LogConfig {
    our enum Level <Debug Info Warn Error>;

    has $.display-level = Debug;

    method instance() {
        state LogConfig $log-config = LogConfig.new;
        $log-config;
    }
}

class Logger {
    method display-level() returns LogConfig::Level {
        LogConfig.instance.display-level;
    }

    method debug($fmt, *@stuffing) {
        self.log(LogConfig::Level::Debug, $fmt, @stuffing);
    }

    method info($fmt, *@stuffing) {
        self.log(LogConfig::Level::Info, $fmt, @stuffing);
    }

    method warn($fmt, *@stuffing) {
        self.log(LogConfig::Level::Warn, $fmt, @stuffing);
    }

    method error($fmt, *@stuffing) {
        self.log(LogConfig::Level::Error, $fmt, @stuffing);
    }

    method log(LogConfig::Level $level, Str:D $fmt, @stuffing) {
        if $level >= $.display-level {
            note sprintf("[%s] [%s] $fmt",
                    $level.Str.lc,
                    ~DateTime.now,
                    |@stuffing,
                );
        }
    }
}

role Loggish {
    has Logger $.logger = Logger.new;

    method debug($fmt, *@stuffing) { $!logger.debug($fmt, |@stuffing) }
    method info($fmt, *@stuffing) { $!logger.info($fmt, |@stuffing) }
    method warn($fmt, *@stuffing) { $!logger.warn($fmt, |@stuffing) }
    method error($fmt, *@stuffing) { $!logger.error($fmt, |@stuffing) }
}

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

    multi method build-from-plan(%config is copy, :$section, :$type-prefix!, Context :$context!, :@include) {
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
                default {
                    die "Unable to load $class-name: $_";
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

    method emit($item) {
        #note "{self.^name} $item<id>";
        $!feed.emit($item)
    }
    method done() { $!feed.done }
    method quit($x) { $!feed.quit($x) }
    multi method Supply { $!feed.Supply }
}

role Component { ...  }

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
            sub ($item) {
                CATCH {
                    default {
                        warn "Failure in {self.^name}: $_";
                        .rethrow;
                    }
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
does Loggish
does Builder {
    has %.plan;
    has %.generators;
    has %.processors;
    has @.run;
    has %.filters =
            :split(&App::Perlocution::Filters::split),
            :map(&App::Perlocution::Filters::map),
            :trim(&App::Perlocution::Filters::trim),# :&markdown,
            :clip-end(&App::Perlocution::Filters::clip-end),
            :clip-start(&App::Perlocution::Filters::clip-start),
            :subst(&App::Perlocution::Filters::subst),
            :subst-re(&App::Perlocution::Filters::subst-re),
            :markdown(&App::Perlocution::Filters::markdown),
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
        self.debug("Configuring %s %s", $type, $real-name);
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

            self.debug("Joining %s <- %s", $processor-name, @source-names.join(", "));
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
    also does Loggish;

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
    my $logger = Logger.new;
    $logger.info("Plan loaded.");
    $plan.execute;
    $logger.info("Fin.");
}
