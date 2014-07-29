use strict;
use warnings;
use Test::More;
use t::Util;

use File::Spec;
use Try::Tiny;

use Workman::Task;
use Workman::Queue::Mock;
use Workman::Server::Profile;
use Workman::Server::Worker::Job;
use Parallel::Scoreboard;
use Sys::SigAction qw/timeout_call/;

my ($result, $e);
my $queue = do {
    Workman::Queue::Mock->new(
        on_done  => sub { $result = shift },
        on_abort => sub { $e      = shift },
        on_wait  => sub { $result         },
    );
};
my $profile    = Workman::Server::Profile->new(queue => $queue, dequeue_interval => 1);
my $scoreboard = Parallel::Scoreboard->new(
    base_dir => File::Spec->catfile(
        File::Spec->tmpdir,
        "test-Workman-scoreboard-$$"
    ),
);

my $worker = Workman::Server::Worker::Job->new(
    profile    => $profile,
    scoreboard => $scoreboard,
);

our ($args, $should_call_foo, $should_call_bar, $should_call_baz);
my $foo_task = Workman::Task->new(Foo => sub {
    $args = shift;
    ok $should_call_foo, 'should be called Foo task.';
    $worker->harakiri(1);
    return { this => { is => 'foo result' } };
});
my $bar_task = Workman::Task->new(Bar => sub {
    $args = shift;
    ok $should_call_bar, 'should be called Bar task.';
    $worker->harakiri(1);
    return { this => { is => 'bar result' } };
});
my $baz_task = Workman::Task->new(Baz => sub {
    $args = shift;
    ok $should_call_baz, 'should be called Baz task.';
    $worker->harakiri(1);
    die { this => { is => 'baz exception' } };
});

$profile->set_task_loader(sub {
    shift->add_task($foo_task)
         ->add_task($bar_task)
         ->add_task($baz_task);
});

my $foo_job = $queue->enqueue(Foo => { this => { is => 'foo args' } });
my $bar_job = $queue->enqueue(Bar => { this => { is => 'bar args' } });
is $foo_task->count, 0, 'should not call Foo yet.';
is $bar_task->count, 0, 'should not call Bar yet.';

subtest 'call foo' => sub {
    local $args;
    local $should_call_foo = 1;
    $result = undef;
    $worker->run;
    is_deeply $args, { this => { is => 'foo args' } }, 'should pass foo args.';
    is_deeply $foo_job->wait, { this => { is => 'foo result' } }, 'should return foo result.';
    is $foo_task->count, 1, 'should call Foo once.';
    is $bar_task->count, 0, 'should not call Bar yet.';
    is $baz_task->count, 0, 'should not call Baz yet.';
};

subtest 'call bar' => sub {
    local $args;
    local $should_call_bar = 1;
    $result = undef;
    $worker->run;
    is_deeply $args, { this => { is => 'bar args' } }, 'should pass bar args.';
    is_deeply $bar_job->wait, { this => { is => 'bar result' } }, 'should return bar result.';
    is $foo_task->count, 1, 'should keep Foo call count.';
    is $bar_task->count, 1, 'should call Bar once.';
    is $baz_task->count, 0, 'should not call Baz yet.';
};

subtest 'call not' => sub {
    local $args;

    my $is_timeout = timeout_call 3 => sub {
        $worker->run;
    };
    note 'timeout' if $is_timeout;

    is_deeply $args, undef, 'should not set args.';
    is $foo_task->count, 1, 'should keep Foo call count.';
    is $bar_task->count, 1, 'should keep Bar call count.';
    is $baz_task->count, 0, 'should not call Baz yet.';
};

subtest 'call baz' => sub {
    local $args;
    local $should_call_baz = 1;
    $result = undef;

    my $baz_job = $queue->enqueue(Baz => { this => { is => 'baz args' } });
    $worker->run;
    is_deeply $args, { this => { is => 'baz args' } }, 'should pass baz args.';
    is $bar_job->wait, undef, 'should not return result.';
    is_deeply $e, { this => { is => 'baz exception' } }, 'should throw baz exception.';
    is $foo_task->count, 1, 'should keep Foo call count.';
    is $bar_task->count, 1, 'should keep Bar call count.';
    is $baz_task->count, 1, 'should call Baz once.'
};

subtest 'call not' => sub {
    local $args;

    my $is_timeout = timeout_call 3 => sub {
        $worker->run;
    };
    note 'timeout' if $is_timeout;

    is_deeply $args, undef, 'should not set args.';
    is $foo_task->count, 1, 'should keep Foo call count.';
    is $bar_task->count, 1, 'should keep Bar call count.';
    is $baz_task->count, 1, 'should keep Baz call count.';
};

done_testing;
