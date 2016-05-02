use strict;
use warnings;
use utf8;

use File::Temp qw/tempfile/;
use Data::Dumper;
use Workman::Server;
use Workman::Server::Profile;
use Workman::Queue::File;
use Workman::Task;

my (undef, $file) = tempfile();
my $queue   = Workman::Queue::File->new(file => $file);
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
warn "[Workman::Queue::File] file: $file";
Workman::Server->new(profile => $profile)->run();
warn "cleanup: $file";

unlink $file;
