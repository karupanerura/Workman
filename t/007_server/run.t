use strict;
use warnings;
use Test::More tests => 5;
use Test::SharedFork 0.28;
use Test::TCP;

use Workman::Task;
use Workman::Queue::File;
use Workman::Server::Profile;
use Workman::Server;
use File::Temp qw/tempfile/;
use POSIX qw/SIGHUP SIGTERM/;

my (undef, $file) = tempfile();

my $worker = Test::TCP->new(
    code => sub {
        my $port    = shift;
        my $queue   = Workman::Queue::File->new(file => $file);
        my $profile = Workman::Server::Profile->new(
            queue       => $queue,
            max_workers => 3,
            admin_port  => $port,
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
        Workman::Server->new(profile => $profile)->run;
        exit 0;
    }
);
sleep 3; # wait while ready

my $pid = $worker->pid;

my $queue = Workman::Queue::File->new(file => $file);
$queue->enqueue(Foo => { this => { is => 'foo args' } });

my $id = $queue->enqueue(Bar => { this => { is => 'bar args' } })->wait->{id};

kill SIGHUP, $pid;
isnt $queue->enqueue(Bar => { this => { is => 'bar args' } })->wait->{id}, $id, 'restart ok';

$worker->stop;
ok !kill(0, $pid), 'shutdown ok';

unlink $file;
