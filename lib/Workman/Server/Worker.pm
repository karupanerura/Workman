package Workman::Server::Worker;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use Try::Tiny;
use POSIX qw/SA_RESTART/;
use Sys::SigAction qw/set_sig_handler/;

use Workman::Server::Exception::TaskNotFound;

use Class::Accessor::Lite
    new => 1,
    ro => [qw/id server/],
    rw => [qw/harakiri current_job/];

sub run {
    my $self = shift;
    $self->harakiri(0);
    $self->set_signal_handler();

    local $0 = "$0 WORKER";
    $self->server->profile->apply($self);
    $self->server->profile->queue->register_tasks( $self->get_all_tasks );
    $self->dequeue_loop();
}

sub set_signal_handler {
    my $self = shift;

    for my $sig (qw/TERM/) {
        $self->{_signal_handler}->{$sig} = set_sig_handler($sig, sub {
            warn "[$$] SIG$sig RECEIVED";
            $self->shutdown($sig);
        }, {
            flags => SA_RESTART
        });
    }

    for my $sig (qw/ABRT/) {
        $self->{_signal_handler}->{$sig} = set_sig_handler($sig, sub {
            warn "[$$] SIG$sig RECEIVED";
            $self->abort($sig);
        }, {
            flags => SA_RESTART
        });
    }
}

sub shutdown :method {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->harakiri(1);
    $self->server->profile->queue->wait_abort();
}

sub abort {
    my ($self, $sig) = @_;

    ## TODO: logging
    $self->shutdown($sig);
    if (my $job = $self->current_job) {
        $job->abort("force killed.");
    }
}

sub register_task {
    my ($self, $task) = @_;
    my $name = $task->name;
    croak "task already registerd. name: $name" if exists $self->{_task}->{$name};
    $self->{_task}->{$name} = $task;
    return $self;
}

sub get_task {
    my ($self, $job) = @_;

    my $name = $job->name;
    return unless exists $self->{_task}->{$name};
    return $self->{_task}->{$name};
}

sub get_all_tasks {
    my $self = shift;
    return values %{ $self->{_task} };
}

sub dequeue_loop {
    my $self = shift;

    my $count = $self->server->profile->max_reqs_par_child;
    my $queue = $self->server->profile->queue;
    until ($self->harakiri) {
        my $job = $queue->dequeue();
        $self->work_job($job) if defined $job;
        $self->harakiri(1)    if --$count == 0;
    }
}

sub work_job {
    my ($self, $job) = @_;
    try {
        warn "[$$] START JOB: ", $job->name;
        my $task = $self->get_task($job) or Workman::Server::Exception::TaskNotFound->throw;
        $self->current_job($job);
        my $result = $task->run($job->args);
        $job->done($result);
    }
    catch {
        warn "[$$] ABORT JOB: ", $job->name, " Error: $_";
        $job->abort($_);
    }
    finally {
        warn "[$$] FINISH JOB: ", $job->name;
        $self->current_job(undef);
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Server - job-queue worker server

=head1 SYNOPSIS


=head1 DESCRIPTION

Workman is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

