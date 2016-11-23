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

    multi method build-from-plan(
        %config is copy,    #= The configuration to build with
        :$section,          #= Name of the section to lookup config keys in the plan
        :$type-prefix!,     #= Prefix to put beofre the type name of the object
        Context :$context!, #= The Context object, used to get the entire plan
        :@include,          #= Additional directories to search for .pm6 files
        :@roles,            #= Additional roles to apply to the constructed object
    ) {
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

        my $o := self!construct($type, \(:$context, |%config));
        $o does $_ for @roles;
        $o;
    }

    multi method build-from-plan(
        %config,            #= The configuration to build with
        :$section,          #= Name of the section to lookup config keys in the plan
        :$type!,            #= Type of object to instantiate
        Context :$context!, #= The Context object, used to get the entire plan
        :@include,          #= Additional directories to search for .pm6 files
        :@roles,            #= Additional roles to apply to the constructed object
    ) {
        my %plan = $context.plan;

        with $section {
            my $config = %config<config> :delete;
            with $config {
                %config =
                    |%plan{ $section }{ $config },
                    |%config;
            }
        }

        my $o := self!construct($type, \(:$context, |%config));
        $o does $_ for @roles;
        $o;
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

role Queue {
    has @.items;
    has Bool $.done = False;
    has Int %!pointers{Int};

    method !this-pointer($key) {
        %!pointers{ $key } //= 0;
    }

    method !next-pointer($key) {
        %!pointers{ $key } //= 0;
        %!pointers{ $key }++;
    }

    #| Add an item to the end of the queue.
    method enq($item) { push @!items, $item }

    #| Pull the next item from the queue, if any.
    method deq($key) { @!items[ self!next-pointer($key) ] }

    #| Has items ready to process.
    method ready($key) { self!this-pointer($key) < @!items }

    #| Has no items ready to process. Exactly the same as !$q.ready.
    method empty($key) { !self.ready($key) }

    #| Return the state of the done flag.
    multi method done() returns Bool:D { $!done }

    #| Set the done flag with True. Passing False is a no-op.
    multi method done(Bool:D $done) { $!done ||= $done }

    #| Return True when both empty and done.
    multi method finished($key) { self.empty($key) and $.done }

    #| Return True when either ready or not yet done.
    multi method running($key) { self.ready($key) or not $.done }
}

class QueueHelper {
    method _ { ... } # abstract, cannot instantiate

    method merge(@queues) {
        return Queue.new if @queues.elems == 0;
        return @queues[0] if @queues.elems == 1;

        class :: does Queue {
            has Queue @.queues;

            method deq($key) {
                my $item;
                if @!items {
                    $item = self.Queue::deq($key);
                }
                else {
                    for @!queues -> $q {
                        if $q.ready($key) {
                            $item = $q.deq($key);
                            last;
                        }
                    }
                }

                self.done([&&] @!queues».done);

                $item;
            }

            method ready($key) {
                die if @!queues[0] === self;
                self.Queue::ready($key) || [||] @!queues».ready($key)
            }
        }.new(queues => @queues);
    }

    method sort($queue, &sorter = &infix:<cmp>) {
        class :: does Queue {
            has $.inner;

            method ready($key) {
                if $!inner.done {
                    push @!items, $!inner.deq($key) while $!inner.ready($key);
                    @!items .= sort(&sorter);
                    self.done(True);
                }

                self.Queue::ready($key);
            }
        }.new(:inner($queue));
    }
}

# role Emitter {
#     method emit($item) { ... }
#     method done() { ... }
#     method quit($x) { ... }
# }

role QueueEmitter {
    has Queue $.outbox .= new;

    method emit($item) { $!outbox.enq($item) }

    method done() { self.*before-done; $!outbox.done(True) }
    method quit($x) { }

    multi method Queue { $!outbox }
}

role AsyncEmitter {
    has Supplier $!feed = Supplier::Preserving.new;

    method emit($item) {
        #note "{self.^name} $item<id>";
        $!feed.emit($item)
    }
    method before-done() { }
    method done() { self.before-done; $!feed.done }
    method quit($x) { $!feed.quit($x) }
    multi method Supply { $!feed.Supply }
}

role Component { ...  }

role Generator {
    also does Component;
    #also does Emitter;

    method generate() { ... }
}

role Processor {
    also does Component;
    #also does Emitter;

    method prepare-producer($helper, @queues) {
        $helper.merge(@queues);
    }

    method process($item) { ... }
}

role QueueProcessor {
    also does QueueEmitter;

    has Queue $.inbox is rw;

    multi method join(@sources) {
        return unless @sources;

        my @queues = @sources».Queue;
        $!inbox = self.prepare-producer(QueueHelper, @queues);
    }
}

role AsyncProcessor {
    also does AsyncEmitter;

    multi method join(@sources) {
        return unless @sources;

        my Supply @supplies = @sources».Supply;
        my $producer = self.prepare-producer(Supply, @supplies);
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
}

class Context
does Loggish
does Builder {
    has @.generator-roles;
    has @.processor-roles;

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
            :section<processors>,
            :roles(@!processor-roles),
        );
    }

    method generator($name) {
        die qq[no configuration for generator named "$name"]
            unless %!plan<generators>{ $name }:exists;

        %.generators{ $name } //= self.build-from-plan(
            %.plan<generators>{ $name },
            :context(self),
            :type-prefix<App::Perlocution::Generator>,
            :section<generators>,
            :roles(@!generator-roles),
        );
    }

    method source($name) {
        my ($type, $real-name) = $name.split(':', 2);
        # self.debug("Configuring %s %s", $type, $real-name);
        my $obj = do given $type {
            when 'generator' { self.generator($real-name) }
            when 'processor' { self.processor($real-name) }
            default {
                die qq[unknown process type "$_"];
            }
        }
    }

    method from-plan(::?CLASS:D: *%plan) {
        self.plan = %plan;
        self.init;
    }

    method init(::?CLASS:D:) {
        @!run = (%!plan<run> // %!generators.keys).map({
            self.generator($^name);
        });

        my %order = %!plan<flow>.keys.BagHash;

        my $last-score = [+] %order.values;
        loop {
            for %!plan<flow>.kv -> $processor-name, $source-names {
                my @source-names = |$source-names.list;

                my $score = [max] gather for @source-names -> $source-name {
                    my ($type, $real-name) = $source-name.split(':', 2);
                    if $type eq 'generator' { take 1 }
                    else                    { take %order{ $real-name } + 1 }
                }

                %order{ $processor-name } = $score;
            }

            last if $last-score == [+] %order.values;
            $last-score = [+] %order.values;
        }

        for %order.sort(*.value <=> *.value)».key -> $processor-name {
            my @source-names = |%!plan<flow>{ $processor-name }.list;
            my $processor = self.processor($processor-name);

            my @sources = @source-names.map(-> $name {
                self.source($name);
            });

            self.debug("Joining %s <- %s", $processor-name, @source-names.join(", "));
            $processor.join(@sources);
        }

        self;
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

# Memory intensive and slow, but no stoopid Perl 6 async boogs
class QueueRunner is Loggish {
    method run($context) {
        my %generators = $context.generators;
        my %processors = $context.processors;

        for %generators.kv -> $name, $g {
            self.info("Generating %s...", $name);
            $g.generate;
            $g.outbox.done(True);
        }

        while (%processors) {
            for %processors.kv -> $name, $p {
                while $p.inbox.ready($p.WHERE) {
                    my %item = $p.inbox.deq($p.WHERE);
                    #self.debug("Process %s: %s", $name, %item.perl);
                    $p.process(%item);
                }

                $p.done if $p.inbox.finished($p.WHERE);
            }

            # Keep only those that still might have stuff to process
            %processors .= grep({ .value.inbox.running(.value.WHERE) });
        }
    }
}

class AsyncRunner {
    method promise-to-run($context) {
        do for $context.run -> $generator {
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

    method run($context) {
        await self.promise-to-run($context);
    }
}

class Plan {
    has $.context;
    has $.runner;

    method execute() {
        $!runner.run($!context);
    }
}

multi load-plan(Str $plan-text) is export {
    my %plan = from-json($plan-text);
    my $context = Context.new(
        generator-roles => [ QueueEmitter ],
        processor-roles => [ QueueProcessor ],
    );
    $context.from-plan(|%plan);
    Plan.new(:$context, :runner(QueueRunner.new));
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
