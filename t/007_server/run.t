use strict;
use warnings;
use Test::More tests => 12;
use Test::SharedFork 0.28;
use Test::TCP;
use t::Util;

use Workman::Task;
use Workman::Queue::File;
use Workman::Server::Profile;
use Workman::Server;
use File::Temp qw/tempfile/;

my (undef, $file) = tempfile(EXLOCK => 0);

my $worker = Test::TCP->new(
    code => sub {
        my $port    = shift;
        my $queue   = Workman::Queue::File->new(file => $file);
        my $profile = Workman::Server::Profile->new(
            queue            => $queue,
            max_workers      => 3,
            admin_port       => $port,
            dequeue_interval => 0.1,
        );

        $profile->set_task_loader(sub {
            my $set = shift;
            my $id  = int rand time;
            $set->add_task(Workman::Task->new(Foo => sub {
                my $args = shift;
                is_deeply $args, { this => { is => 'foo args' } }, 'should work foo job';
                return { id => $id };
            }));
            $set->add_task(Workman::Task->new(Bar => sub {
                my $args = shift;
                is_deeply $args, { this => { is => 'bar args' } }, 'should work bar job';
                return { id => $id };
            }));
        });

        my %pid;
        my $server = Workman::Server->new(
            profile => $profile,
            on_fork => sub {
                my $pid = shift;
                $pid{$pid} = 1;
                is $pid, $$, 'should called `on_fork` callback in child process.';

                srand();
            },
            on_leap => sub {
                my $pid = shift;
                delete $pid{$pid};
            }
        );
        $server->run;
        is scalar %pid, 0, 'should dead all children.';

        exit 0;
    }
);
sleep 3; # wait while ready

my $pid = $worker->pid;

my $queue = Workman::Queue::File->new(file => $file);
$queue->enqueue(Foo => { this => { is => 'foo args' } });

my $id1 = $queue->enqueue(Bar => { this => { is => 'bar args' } })->wait->{id};
note "id: $id1";

kill HUP => $pid;
sleep 3;

my $id2 = $queue->enqueue(Bar => { this => { is => 'bar args' } })->wait->{id};
isnt $id2, $id1, 'restart ok';

$worker->stop;
ok !kill(0, $pid), 'shutdown ok';

unlink $file;
