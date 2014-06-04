package Workman::Server::Worker;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use Try::Tiny;
use Workman::Server::Exception::TaskNotFound;

use Class::Accessor::Lite
    new => 1,
    ro => [qw/id server/],
    rw => [qw/harakiri current_job/];

sub run {
    my $self = shift;
    $self->harakiri(0);

    # localize and set signal handler
    local $SIG{INT}  = $SIG{INT};
    local $SIG{TERM} = $SIG{TERM};
    local $SIG{HUP}  = $SIG{HUP};
    $self->set_signal_handler();

    local $0 = "$0 WORKER";
    $self->dequeue_loop();
}

sub set_signal_handler {
    my $self = shift;

    for my $sig (qw/INT TERM HUP/) {
        $SIG{$sig} = sub {
            ## TODO: logging
            $self->harakiri(1);
        }
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

sub dequeue_loop {
    my $self = shift;

    my $count = $self->server->profile->max_reqs_par_child;
    my $queue = $self->server->profile->queue;
    until ($self->harakiri) {
        my $job = $queue->dequeue();
        $self->current_job();
        $self->work_job($job);
        $self->harakiri(1) if --$count == 0;
    }
}

sub work_job {
    my ($self, $job) = @_;
    try {
        # TODO: logging
        my $task   = $self->get_task($job) or Workman::Server::Exception::TaskNotFound->throw;
        my $result = $task->run($job->args);
        $job->done($result);
    }
    catch {
        # TODO: logging
        $job->abort($_);
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

