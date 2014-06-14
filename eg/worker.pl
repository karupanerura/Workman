use strict;
use warnings;
use utf8;
use 5.10.0;

use Workman::Server;
use Workman::Server::Profile;
use Workman::Queue::Gearman;
use Workman::Task;
use Data::Dumper;

my $queue   = Workman::Queue::Gearman->new(job_servers => ['127.0.0.1:7003']);
my $profile = Workman::Server::Profile->new(max_workers => 10, queue => $queue);
$profile->register(sub {
    my $worker = shift;

    warn "[$$] register tasks...";
    my $task = Workman::Task->new(Echo => sub {
        my $args = shift;
        warn Dumper $args;
        die "oops!!";
        return $args;
    });
    $worker->register_task($task);
});

# start
Workman::Server->new(profile => $profile)->run();
