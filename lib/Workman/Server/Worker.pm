package Workman::Server::Worker;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use POSIX qw/SA_RESTART/;
use Sys::SigAction qw/set_sig_handler/;
use Class::Data::Lazy qw/type/;
use JSON::XS;

use Class::Accessor::Lite
    new => 1,
    ro => [qw/profile scoreboard/];

sub run {
    my $self = shift;
    $self->set_signal_handler();

    local $0 = sprintf '%s %s WORKER', $0, uc $self->type;
    $self->_run();
}

sub _build_type {
    my $invocant = shift;
    my $class    = ref $invocant || $invocant;
    (my $type = $class) =~ s/^Workman::Server::Worker:://;
    return $type;
}

sub _run { die "this is abstract method." }

sub set_signal_handler {
    my $self = shift;

    # to ignore signal propagation
    $SIG{INT} = 'IGNORE';

    # to shutdown
    for my $sig (qw/TERM HUP/) {
        $self->{_signal_handler}->{$sig} = set_sig_handler($sig, sub {
            warn "[$$] SIG$sig RECEIVED";
            $self->shutdown($sig);
        }, {
            flags => SA_RESTART
        });
    }

    # to force shutdown
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
    die "signal recieved: SIG$sig";
}

sub abort {
    my ($self, $sig) = @_;
    $self->shutdown($sig);
}

sub json {
    my $self = shift;
    return $self->{json} ||= JSON::XS->new->utf8;
}

sub update_scoreboard_status {
    my ($self, $status, $data) = @_;
    $self->scoreboard->update(
        $self->json->encode({
            %$data,
            status => $status,
        })
    );
}

1;
__END__
