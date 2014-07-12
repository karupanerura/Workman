use strict;
use warnings;
use Test::More tests => 10;

use Workman::Task;

my $args;
my $count = 0;
my $task = Workman::Task->new(Foo => sub {
    $args = shift;
    $count++;
    return { it => { is => 'result', count => $count } };
});
isa_ok $task, 'Workman::Task';
is $count, 0, 'should not called yet';
is $task->count, 0, 'should set count 0 by default';

is_deeply $task->run({ foo => 'bar' }), { it => { is => 'result', count => $count } }, 'should return the return value of callback';
is_deeply $args, { foo => 'bar' }, 'should pass args';
is $count, 1, 'should call once';

is_deeply $task->run({ hoge => 'fuga' }), { it => { is => 'result', count => $count } }, 'should not cache return value';
is_deeply $args, { hoge => 'fuga' }, 'should not cache args';
is $count, 2, 'should call once';
is $task->count, $count, 'should get call count';
