use strict;
use warnings;
use Test::More;

use Workman::Task;
use Workman::Task::Set;

my $set = Workman::Task::Set->new;
isa_ok $set, 'Workman::Task::Set';

my $foo_task = Workman::Task->new(Foo => sub {});
ok !$set->exists('Foo'), '$set->exists should return false value.';
is $set->add_task($foo_task), $set,  '$set->add_task should return same instance.';
is $set->get_task('Foo'), $foo_task, '$set->get_task should return same task.';
ok $set->exists('Foo'), '$set->exists should return true value.';

my $bar_task = Workman::Task->new(Bar => sub {});
is eval { $set->add_task($bar_task); 1 }, 1, '$set->add_task should not die when passed yet registerd named task.';
is $set->get_task('Bar'), $bar_task, '$set->get_task should return same task.';

subtest 'when passed already registerd named task' => sub {
    my ($line, $file) = (__LINE__, __FILE__); is eval { $set->add_task(Workman::Task->new(Foo => sub {})); 1 }, undef
        , '$set->add_task should croak.';
    is $@, "task already registerd. name: Foo at $file line $line.$/"
        , 'error message is valid.';
    is $set->get_task('Foo'), $foo_task, 'should not broke instance.';
};

is eval { $set->add_class('t::Task::Foo'); 1 }, 1, '$set->add_class should not die when passed yet registerd task.';
isa_ok $set->get_task('t::Task::Foo'), 't::Task::Foo', '$set->get_task should return instance of t::Task::Foo.';

is_deeply [sort $set->get_all_tasks], [sort $foo_task, $bar_task, $set->get_task('t::Task::Foo')]
    => '$set->get_all_tasks should return all registerd tasks';

is_deeply [sort $set->get_all_task_names], [sort 'Foo', 'Bar', 't::Task::Foo']
    => '$set->get_all_task_names should return name of all registerd tasks';

subtest 'when cloned' => sub {
    my $cloned_set = $set->clone;
    isnt $cloned_set, $set, '$set->clone should not return same instance.';
    is $cloned_set->clear, $cloned_set, '$cloned_set->clear should return same instance.';
    ok !$cloned_set->exists('Foo'), '$cloned_set->exists should return false value.';
    is scalar $cloned_set->get_task('Foo'), undef, '$cloned_set->get should return undef value.';
    is_deeply [$cloned_set->get_all_tasks], [], '$cloned_set->get_all_tasks return empty.';
    is_deeply [$cloned_set->get_all_task_names], [], '$cloned_set->get_all_task_names return empty.';
    ok $set->exists('Foo'), 'but, $set should be not broken.';
};

subtest 'when merged' => sub {
    my $set1 = $set->clone;
    my $set2 = Workman::Task::Set->new->add_task(Workman::Task->new(Fuga => sub {}))->add_task(Workman::Task->new(Hoge => sub {}));
    $set1->merge($set2);
    note explain [sort $set1->get_all_task_names];
    is_deeply [sort $set1->get_all_task_names], [sort qw/Bar Foo Fuga Hoge t::Task::Foo/], 'expected task names ok.';
};

subtest 'overload of add method' => sub {
    my $set2 = Workman::Task::Set->new->add_task(Workman::Task->new(Fuga => sub {}));
    is eval { $set->add(Workman::Task->new(Hoge => sub {})); 1 }, 1, '$set->add() allow pass Workman::Task object.';
    is eval { $set->add('t::Task::Bar');                     1 }, 1, '$set->add() allow pass Workman::Task::Class.';
    is eval { $set->add($set2);                              1 }, 1, '$set->add() allow pass Workman::Task::Set object.';
    is_deeply [sort $set->get_all_task_names], [sort qw/Bar Foo Fuga Hoge t::Task::Bar t::Task::Foo/], 'expected task names ok.';
};

done_testing;
