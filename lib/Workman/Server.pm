package Workman::Server;
use strict;
use warnings;
use utf8;

use Time::HiRes;
use Parallel::Prefork;
use POSIX qw/SA_RESTART/;
use Sys::SigAction qw/set_sig_handler/;

use Workman::Server::Worker;

use Class::Accessor::Lite new => 1, ro => [qw/profile/];

sub pm {
    my $self = shift;
    return $self->{_pm} ||= Parallel::Prefork->new({
        max_workers => $self->profile->max_workers,
        after_fork  => sub {
            my (undef, $pid) = @_;
            # TODO: logging
            warn "[$pid] START WORKER";
        },
        on_child_reap => sub {
            my (undef, $pid) = @_;
            # TODO: logging
            warn "[$pid] FINISH WORKER";
        },
        trap_signals => {
            INT  => 'TERM', # graceful shutdown (timeout: infiniy)
            TERM => 'TERM', # graceful shutdown
            HUP  => 'HUP',  # graceful restart
        },
    });
}

sub run {
    my $self = shift;

    # localize and set signal handler
    my $pm = $self->pm;
    $self->set_signal_handler();

    # TODO: use logger
    warn "[$$] START";

    my $id = 0;
    until ($pm->signal_received eq 'TERM') {
        $pm->start(sub {
            srand();
            Workman::Server::Worker->new(
                id     => $id++,
                server => $self,
            )->run;
        });
    }
    $pm->wait_all_children();

    # TODO: use logger
    warn "[$$] SHUTDOWN";
}

sub set_signal_handler {
    my $self = shift;

    for my $sig (qw/INT TERM/) {
        $self->{_signal_handler}->{$sig} = set_sig_handler($sig, sub {
            warn "[$$] SIG$sig RECEIVED";
            $self->pm->signal_received($self->pm->trap_signals->{$sig}) if exists $self->pm->trap_signals->{$sig};
            $self->shutdown($sig);
        }, {
            flags => SA_RESTART
        });
    }

    for my $sig (qw/HUP/) {
        $self->{_signal_handler}->{$sig} = set_sig_handler($sig, sub {
            warn "[$$] SIG$sig RECEIVED";
            $self->pm->signal_received($self->pm->trap_signals->{$sig}) if exists $self->pm->trap_signals->{$sig};
            $self->kill_all_children();
        }, {
            flags => SA_RESTART
        });
    }
}

sub shutdown :method {
    my ($self, $sig) = @_;

    $self->kill_all_children();

    my $start_at = [Time::HiRes::gettimeofday];
    while (Time::HiRes::tv_interval($start_at) < $self->profile->graceful_shutdown_timeout) {
        # FIXME: non-blocking wait_all_children
        #        TODO: pull-req to Parallel::Prefork
        if (my ($pid) = $self->pm->_wait(0)) {
            if (delete $self->pm->{worker_pids}->{$pid}) {
                $self->pm->_on_child_reap($pid, $?);
            }
        }
        last unless $self->pm->num_workers;
    }
    continue {
        Time::HiRes::sleep $self->profile->wait_interval;
    }

    if ($self->pm->num_workers) {
        # TODO: use logger
        warn "[$$] give up graceful shutdown. force shutdown!!";
        $self->pm->signal_all_children('ABRT'); # force kill children.
    }
}

sub kill_all_children {
    my $self = shift;

    # TODO: use logger
    $self->pm->signal_all_children('TERM');
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

