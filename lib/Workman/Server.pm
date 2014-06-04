package Workman::Server;
use strict;
use warnings;
use utf8;

use Time::HiRes;
use Parallel::Prefork;
use Workman::Server::Worker;

use Class::Accessor::Lite new => 1, ro => [qw/profile/];

our $WAIT_INTERVAL = 0.1;

sub pm {
    my $self = shift;
    return $self->{_pm} ||= Parallel::Prefork->new({
        max_workers   => $self->profile->max_workers,
        on_child_reap => sub {
            # TODO: logging
        },
        trap_signals  => {
            INT  => 'TERM', # graceful shutdown (timeout: infiniy)
            TERM => 'TERM', # graceful shutdown
            HUP  => 'TERM', # graceful restart
        },
    });
}

sub run {
    my $self = shift;

    # localize and set signal handler
    local $SIG{INT}  = $SIG{INT};
    local $SIG{TERM} = $SIG{TERM};
    local $SIG{HUP}  = $SIG{HUP};
    $self->set_signal_handler();

    my $id = 0;
    until ($self->signal_received eq 'TERM') {
        $self->pm->start(sub {
            Workman::Server::Worker->new(
                id     => $id++,
                server => $self,
            )->run;
        });
    }
    $self->pm->wait_all_children();

    # TODO: logging
    #     info shutdown
}

sub set_signal_handler {
    my $self = shift;

    for my $sig (qw/INT TERM HUP/) {
        $SIG{$sig} = sub {
            # TODO: logging
            #     debug: "trap signal: $sig"
            #     info:  "start graceful shutdown $0"
            $self->pm->signal_all_children('TERM');

            my $start_at = [Time::HiRes::gettimeofday];
            while (Time::HiRes::tv_inteval($start_at) < $self->graceful_shutdown_timeout) {
                # FIXME: non-blocking wait_all_children
                #        TODO: pull-req to Parallel::Prefork
                for my $pid (sort keys %{ $self->pm->{worker_pids} }) {
                    $self->pm->_wait(0);
                }
                last unless %{ $self->pm->{worker_pids} };
            }
            continue {
                Time::HiRes::sleep $WAIT_INTERVAL;
            }

            #     warn: "give up graceful shutdown. force shutdown!!";
            $self->pm->signal_all_children('KILL'); # force kill children.
            $self->pm->wait_all_children();
        };
    }
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

