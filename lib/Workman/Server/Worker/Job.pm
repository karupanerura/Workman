package Workman::Server::Worker::Job;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Server::Worker/;

use Class::Accessor::Lite rw => [qw/stat harakiri current_job task_set/];

use Carp qw/croak/;
use Try::Tiny;
use Log::Minimal qw/warnf/;

use Workman::Server::Exception::TaskNotFound;
use Workman::Server::Exception::ForceKilled;
use Workman::Server::Exception::DequeueAbort;
use Workman::Server::Util qw/safe_sleep/;

sub _run {
    my $self = shift;
    $self->stat(+{
        abort => 0,
        done  => 0,
    });
    $self->harakiri(0);
    $self->update_scoreboard_status_starting();
    $self->task_set( $self->profile->load_task() );
    $self->profile->queue->register_tasks( $self->task_set );
    $self->dequeue_loop();
    $self->update_scoreboard_status_shutdown();
}

# override
sub shutdown :method {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->harakiri(1);
    $self->profile->queue->dequeue_abort();
}

# override
sub abort {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->shutdown($sig);
    if ($self->current_job) {
        Workman::Server::Exception::ForceKilled->throw(message => 'force killed.');
    }
}


sub dequeue_loop {
    my $self = shift;

    my $dequeue_interval = $self->profile->dequeue_interval;

    my $count = $self->profile->max_reqs_par_child;
    my $queue = $self->profile->queue;
    until ($self->harakiri) {
        my $job = try {
            $self->update_scoreboard_status_waiting();
            $queue->dequeue();
        }
        catch {
            my $e = $_;
            if (Workman::Server::Exception::DequeueAbort->caught($e)) {
                warnf '[%d] dequeue aborted. message: %s', $$, $e->message;
                return undef;
            }
            else {
                die $e; # rethrow
            }
        };

        if (defined $job) {
            $self->work_job($job);
            $self->harakiri(1) if --$count == 0;
        }
        elsif ($dequeue_interval) {
            safe_sleep $dequeue_interval;
        }
    }
}

sub work_job {
    my ($self, $job) = @_;
    my $task = $self->task_set->get_task($job->name);
    try {
        unless ($task) {
            Workman::Server::Exception::TaskNotFound->throw(
                message => "task:@{[ $job->name ]} is not found.",
            );
        }
        $self->update_scoreboard_status_running($job);
        $self->current_job($job);
        my $result = $task->run($job->args);
        $job->done($result);
        $self->stat->{done}++;
    }
    catch {
        $self->stat->{abort}++;
        $self->update_scoreboard_status_aborting($job, $_);
        $job->abort($_);
        $task->on_abort($_) if $task;
    }
    finally {
        $self->update_scoreboard_status_finishing($job);
        $self->current_job(undef);
    };
}

sub update_scoreboard_status_starting {
    my $self = shift;
    $self->update_scoreboard_status(starting => {
        stat => $self->stat,
    });
}

sub update_scoreboard_status_waiting {
    my $self = shift;
    $self->update_scoreboard_status(waiting => {
        stat => $self->stat,
    });
}

sub update_scoreboard_status_running {
    my ($self, $job) = @_;
    $self->update_scoreboard_status(running => {
        stat => $self->stat,
        job => +{
            name => $job->name,
            args => $job->args,
        },
    });
}

sub update_scoreboard_status_aborting {
    my ($self, $job, $e) = @_;
    $self->update_scoreboard_status(aborting => {
        stat => $self->stat,
        job => +{
            name  => $job->name,
            args  => $job->args,
            error => "$e",
        },
    });
}

sub update_scoreboard_status_finishing {
    my ($self, $job) = @_;
    $self->update_scoreboard_status(finishing => {
        stat => $self->stat,
        job  => {
            name => $job->name,
            args => $job->args,
        }
    });
}

sub update_scoreboard_status_shutdown {
    my $self = shift;
    $self->update_scoreboard_status(shutdown => {
        stat => $self->stat,
    });
}

1;
__END__
