package main;
use strict;
use warnings;
use Test::More tests => 11;
use t::Util;
use t::Task::Foo;

my $task = t::Task::Foo->new;
isa_ok $task, 'Workman::Task';
is $task->name, 't::Task::Foo', 'should set name ClassName.';
is $t::Task::Foo::COUNT, 0, 'should not called yet';
is $task->count, 0, 'should set count 0 by default';

is_deeply $task->run({ foo => 'bar' }), { it => { is => 'result', count => $t::Task::Foo::COUNT } }, 'should return the return value of callback';
is_deeply $t::Task::Foo::ARGS, { foo => 'bar' }, 'should pass args';
is $t::Task::Foo::COUNT, 1, 'should call once';

is_deeply $task->run({ hoge => 'fuga' }), { it => { is => 'result', count => $t::Task::Foo::COUNT } }, 'should not cache return value';
is_deeply $t::Task::Foo::ARGS, { hoge => 'fuga' }, 'should not cache args';
is $t::Task::Foo::COUNT, 2, 'should call once';
is $task->count, $t::Task::Foo::COUNT, 'should get call count';
