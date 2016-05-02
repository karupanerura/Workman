use strict;
use warnings;

use Data::Dumper;
use Workman::Server;
use Workman::Server::Profile;
use Workman::Queue::Gearman;
use Workman::Task;

my $queue   = Workman::Queue::Gearman->new(job_servers => [qw/127.0.0.1:7003/]);
my $profile = Workman::Server::Profile->new(max_workers => 10, queue => $queue, dequeue_interval => 0.1);
$profile->set_task_loader(sub {
    my $set = shift;

    warn "[$$] register tasks...";
    $set->add(
	Workman::Task->new(Echo => sub {
            my $args = shift;
            warn Dumper $args;
            return $args;
        })
    );
    $set->add(
	Workman::Task->new(Abort => sub {
            my $args = shift;
            die Dumper $args;
            return;
        })
    );
    $set->add(
	Workman::Task->new(Busy => sub {
            my $args = shift;
            sleep 1 for 1..1000;
            return;
        })
    );
});

# start
warn "[Workman::Queue::Gearman]";
Workman::Server->new(profile => $profile)->run();
