package Workman::Server::SignalHandler;
use strict;
use warnings;
use utf8;

use POSIX qw/SA_RESTART/;
use Sys::SigAction qw/set_sig_handler/;
use Socket qw/AF_UNIX SOCK_STREAM PF_UNSPEC/;
use IO::Select;
use Time::HiRes qw/gettimeofday tv_interval/;

use constant MAX_SUPPORT_SIGNAL_LENGTH => 10;

sub new {
    my $class = shift;

    socketpair my $sig_rdr, my $sig_wtr, AF_UNIX, SOCK_STREAM, PF_UNSPEC or die $!;
    my $sig_select = IO::Select->new($sig_rdr);

    return bless {
        sig_select => $sig_select,
        sig_rdr    => $sig_rdr,
        sig_wtr    => $sig_wtr,
        handler    => {},
        callback   => {},
    } => $class;
}

sub register {
    my ($self, $sig, $cb) = @_;

    push @{ $self->{callback}->{$sig} } => $cb;
    $self->{handler}->{$sig} ||= set_sig_handler($sig, sub {
        $self->_trap_signal($sig);
    }, {
        flags => SA_RESTART
    });

    return $self;
}

sub _trap_signal {
    my ($self, $sig) = @_;

    warn "[$$] SIG$sig RECEIVED"; ## TODO: use logger
    if ($self->{in_sleep}) {
        my $len = length $sig;
        my $ret = syswrite $self->{sig_wtr}, $sig, $len;
        die $! if $ret != $len;
    }
    else {
        $self->_handle_signal($sig);
    }
}

sub _handle_signal {
    my ($self, $sig) = @_;
    $_->() for @{ $self->{callback}->{$sig} };
}

sub sleep :method {
    my ($self, $sec) = @_;
    local $self->{in_sleep} = 1;

    my ($start_at, $finish_at) = ([gettimeofday], undef);
    if (my ($sig_rdr) = $self->{sig_select}->can_read($sec)) {
        my $ret = sysread $sig_rdr, my $sig, MAX_SUPPORT_SIGNAL_LENGTH;
	die $! if !$ret && $!;
        $finish_at = [gettimeofday];
        warn "[$$] interrupt in sleep: $sig";
	$self->_handle_signal($sig);
    }
    else {
        $finish_at = [gettimeofday];
    }

    return tv_interval($start_at, $finish_at);
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

Workman::Server::SignalHandler - internal module to provide signal handling and signal safely sleep for Workman::Server

=head1 SYNOPSIS

    use Workman::Server::SignalHandler;

    our $SLEEP = sub { CORE::sleep @_ };
    BEGIN {
        *CORE::GLOBAL::sleep = sub ($) {## no critic
            $SLEEP->(@_);
        }
    }

    my $handler = Workman::Server::SignalHandler->new();
    $handler->register(HUP  => sub { ... });
    $handler->register(TERM => sub { ... });

    local $SLEEP = sub { $handler->sleep(@_) };
    sleep 1; ## signal safe.

=head1 DESCRIPTION

This module is internal module.
DO NOT USE DIRECTRY.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
