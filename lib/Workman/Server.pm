package Workman::Server;
use strict;
use warnings;
use utf8;

use Time::HiRes;
use Parallel::Prefork 0.17;
use Parallel::Scoreboard;
use File::Spec;
use List::Util qw/sum/;
use List::MoreUtils qw/any/;
use Proc::Guard;

use Workman::Server::Worker::Job;
use Workman::Server::Worker::Admin;

use Class::Accessor::Lite
    new => 1,
    ro  => [qw/profile name/];

sub scoreboard {
    my $self = shift;
    return $self->{_scoreboard} ||= Parallel::Scoreboard->new(
        base_dir => File::Spec->catfile(
            File::Spec->tmpdir,
            $self->name || 'workman-server',
        )
    );
}

sub run {
    my $self = shift;

    # TODO: use logger
    warn "[$$] START";
    my $pm = $self->_create_parallel_prefork();

    my $wait_admin_workers = $self->_create_admin_workers();
    my $wait_job_workers   = $self->_create_job_workers($pm);

    $wait_job_workers->();
    $wait_admin_workers->();

    # TODO: use logger
    warn "[$$] SHUTDOWN";
}

sub _create_parallel_prefork {
    my $self = shift;
    return Parallel::Prefork->new({
        max_workers    => $self->profile->max_workers(),
        spawn_interval => $self->profile->spawn_interval(),
        after_fork     => sub {
            my (undef, $pid) = @_;
            # TODO: logging
            warn "[$pid] START JOB WORKER";
        },
        on_child_reap => sub {
            my (undef, $pid) = @_;
            # TODO: logging
            warn "[$pid] FINISH JOB WORKER";
        },
        trap_signals => {
            INT  => 'TERM', # graceful shutdown
            TERM => 'TERM', # graceful shutdown
            HUP  => 'HUP',  # graceful restart
        },
    });
}

sub _create_admin_workers {
    my $self = shift;

    my $worker = Workman::Server::Worker::Admin->new(profile => $self->profile, scoreboard => $self->scoreboard);
    my $guard  = Proc::Guard->new(code => sub { $worker->run });

    my $pid = $guard->pid;
    warn "[$pid] START ADMIN WORKER";
    return sub {
        $guard->stop;
        warn "[$pid] STOP ADMIN WORKER";
    };
}

sub _create_job_workers {
    my ($self, $pm) = @_;

    my $worker = Workman::Server::Worker::Job->new(profile => $self->profile, scoreboard => $self->scoreboard);
    $pm->start(sub { $worker->run() }) while $pm->signal_received ne 'INT' and $pm->signal_received ne 'TERM';
    return sub {
        my $is_timeout = $pm->wait_all_children($self->profile->graceful_shutdown_timeout);
        if ($is_timeout) {
            # TODO: use logger
            warn "[$$] give up graceful shutdown. force shutdown!!";
            $pm->signal_all_children('ABRT'); # force kill children.
        }
        $pm->wait_all_children();
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

