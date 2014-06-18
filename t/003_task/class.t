package Mock::Task;
use strict;
use warnings;
use parent qw/Workman::Task::Class/;

our $ARGS;
our $COUNT = 0;

sub work_job {
    my ($self, $args) = @_;
    $ARGS = $args;
    $COUNT++;
    return { it => { is => 'result', count => $COUNT } };
}

package main;
use strict;
use warnings;
use Test::More tests => 11;

my $task = Mock::Task->new;
isa_ok $task, 'Workman::Task';
is $task->name, 'Mock::Task', 'should set name ClassName.';
is $Mock::Task::COUNT, 0, 'should not called yet';
is $task->count, 0, 'should set count 0 by default';

is_deeply $task->run({ foo => 'bar' }), { it => { is => 'result', count => $Mock::Task::COUNT } }, 'should return the return value of callback';
is_deeply $Mock::Task::ARGS, { foo => 'bar' }, 'should pass args';
is $Mock::Task::COUNT, 1, 'should call once';

is_deeply $task->run({ hoge => 'fuga' }), { it => { is => 'result', count => $Mock::Task::COUNT } }, 'should not cache return value';
is_deeply $Mock::Task::ARGS, { hoge => 'fuga' }, 'should not cache args';
is $Mock::Task::COUNT, 2, 'should call once';
is $task->count, $Mock::Task::COUNT, 'should get call count';
