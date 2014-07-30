package Workman::Server;
use strict;
use warnings;
use utf8;

use Time::HiRes;
use Parallel::Prefork 0.17;
use Parallel::Scoreboard;
use File::Spec;
use List::Util 1.35 qw/sum any/;
use Proc::Guard;
use Log::Minimal qw/infof warnf/;

use Workman::Server::Worker::Job;
use Workman::Server::Worker::Admin;

use Class::Accessor::Lite
    new => 1,
    ro  => [
        qw/profile name on_fork on_leap/, # args
        qw/admin_pid job_worker_pids job_worker_generation/,   # stat
    ];

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

    infof '[%d] START', $$;
    my $pm = $self->_create_parallel_prefork();

    my $wait_admin_workers = $self->_create_admin_workers();
    my $wait_job_workers   = $self->_create_job_workers($pm);

    $wait_job_workers->();
    $wait_admin_workers->();

    infof '[%d] SHUTDOWN', $$;
}

sub _create_parallel_prefork {
    my $self = shift;
    my $on_leap = $self->on_leap;
    $self->{job_worker_generation} = 0;
    $self->{job_worker_pids}       = {};
    return Parallel::Prefork->new({
        max_workers    => $self->profile->max_workers(),
        spawn_interval => $self->profile->spawn_interval(),
        after_fork     => sub {
            my (undef, $pid) = @_;
            infof '[%d] START JOB WORKER', $pid;
            $self->{job_worker_pids}->{$pid} = $self->{job_worker_generation};
        },
        on_child_reap => sub {
            my (undef, $pid) = @_;
            infof '[%d] FINISH JOB WORKER', $pid;
            $self->{_reapd_job_worker_pids}->{$$} = delete $self->{job_worker_pids}->{$pid};
            $on_leap->($pid) if $on_leap;
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

    my $pid = $self->{admin_pid} = $guard->pid;
    infof '[%d] START ADMIN WORKER', $pid;
    return sub {
        $guard->stop;
        infof '[%d] STOP ADMIN WORKER', $pid;
    };
}

sub _create_job_workers {
    my ($self, $pm) = @_;

    local $SIG{ALRM} = $SIG{ALRM};
    my $worker  = Workman::Server::Worker::Job->new(profile => $self->profile, scoreboard => $self->scoreboard);
    my $on_fork = $self->on_fork;
    until ($self->_check_signal($pm)) {
        $pm->start(sub {
            $on_fork->($$) if $on_fork;
            $worker->run();
        });
    }
    return sub {
        my $is_timeout = $pm->wait_all_children($self->profile->graceful_shutdown_timeout);
        if ($is_timeout) {
            warnf '[%d] give up graceful shutdown. force shutdown!!', $$;
            $pm->signal_all_children('ABRT'); # force kill children.
        }
        $pm->wait_all_children();
    };
}

sub _check_signal {
    my ($self, $pm) = @_;
    return 1 if $pm->signal_received eq 'INT';
    return 1 if $pm->signal_received eq 'TERM';

    if ($pm->signal_received eq 'HUP') {
        my $old_generation = $self->{job_worker_generation}++;

        my $super  = $SIG{ALRM};
        $SIG{ALRM} = sub {
            my @target_pids = grep { $self->{job_worker_pids}->{$_} <= $old_generation } keys %{ $self->{job_worker_pids} };
            if (@target_pids) {
                warnf '[%d] give up graceful restart. force shutdown child process!!', $$;
                kill ABRT => @target_pids; # force kill children.
            }
            $SIG{ALRM} = $super;
        };
        alarm $self->profile->graceful_shutdown_timeout;

    }

    return 0;
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

