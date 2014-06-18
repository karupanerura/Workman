package Workman::Server::Worker::Job;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Server::Worker/;

use Class::Accessor::Lite rw => [qw/harakiri current_job task_set/];

use Carp qw/croak/;
use Try::Tiny;

use Workman::Server::Exception::TaskNotFound;

sub _run {
    my $self = shift;
    $self->harakiri(0);
    $self->update_scoreboard_status_starting();
    $self->task_set( $self->server->profile->load_task() );
    $self->server->profile->queue->register_tasks( $self->task_set );
    $self->dequeue_loop();
    $self->update_scoreboard_status_shutdown();
}

# override
sub shutdown :method {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->harakiri(1);
    $self->server->profile->queue->dequeue_abort();
}

# override
sub abort {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->shutdown($sig);
    die "force killed." if $self->current_job;
}


sub dequeue_loop {
    my $self = shift;

    my $count = $self->server->profile->max_reqs_par_child;
    my $queue = $self->server->profile->queue;
    until ($self->harakiri) {
        my $job = try {
            $self->update_scoreboard_status_waiting();
            $queue->dequeue();
        }
        catch {
            warn $_;
            undef;
        };

        $self->work_job($job) if defined $job;
        $self->harakiri(1)    if --$count == 0;
    }
}

sub work_job {
    my ($self, $job) = @_;
    try {
        my $task = $self->task_set->get_task($job->name) or Workman::Server::Exception::TaskNotFound->throw;
        $self->update_scoreboard_status_running($job);
        $self->current_job($job);
        my $result = $task->run($job->args);
        $job->done($result);
    }
    catch {
        $self->update_scoreboard_status_aborting($job, $_);
        $job->abort($_);
    }
    finally {
        $self->update_scoreboard_status_finishing($job);
        $self->current_job(undef);
    };
}

sub update_scoreboard_status_starting {
    my $self = shift;
    $self->update_scoreboard_status(starting => {});
}

sub update_scoreboard_status_waiting {
    my $self = shift;
    $self->update_scoreboard_status(waiting => {});
}

sub update_scoreboard_status_running {
    my ($self, $job) = @_;
    warn "[$$] START JOB: ", $job->name;
    $self->update_scoreboard_status(running => {
        job => +{
            name => $job->name,
            args => $job->args,
        },
    });
}

sub update_scoreboard_status_aborting {
    my ($self, $job, $e) = @_;
    warn "[$$] ABORT JOB: ", $job->name, " Error: $e";
    $self->update_scoreboard_status(aborting => {
        job => +{
            name => $job->name,
            args => $job->args,
        },
    });
}

sub update_scoreboard_status_finishing {
    my ($self, $job) = @_;
    warn "[$$] FINISH JOB: ", $job->name;
    $self->update_scoreboard_status(finishing => {
        job => {
            name => $job->name,
            args => $job->args,
        }
    });
}

sub update_scoreboard_status_shutdown {
    my $self = shift;
    $self->update_scoreboard_status(shutdown => {});
}

1;
__END__
