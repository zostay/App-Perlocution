use v6;

use Test;
use Perlocution;

my $plan = load-plan(q:to/END_OF_PLAN/);
{
    "generators" : {
        "some-things" : {
            "type" : "FromList",
            "items" : [
                { "id" : "a" },
                { "id" : "b" },
                { "id" : "c" },
                { "id" : "d" }
            ]
        }
    },
    "processors" : {
        "!one" : {
            "fields" : {
                "value" : 1
            }
        },
        "modify-things" : {
            "type" : "AddFields",
            "config" : "!one"
        }
    },
    "flow" : {
        "modify-things" : [ "generator:some-things" ]
    }
}
END_OF_PLAN

$plan.execute;

my @things = |$plan.context.processor('modify-things').Queue.list;
is-deeply @things, [
    { id => 'a', value => 1 },
    { id => 'b', value => 1 },
    { id => 'c', value => 1 },
    { id => 'd', value => 1 },
], 'plan ran the test correctly';

done-testing;

