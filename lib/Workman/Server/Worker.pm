package Workman::Server::Worker;
use strict;
use warnings;
use utf8;

use Carp qw/croak/;
use Class::Data::Lazy qw/type/;
use JSON::XS;
use Workman::Server::SignalHandler;
use Workman::Server::Util;

use Class::Accessor::Lite
    new => 1,
    ro => [qw/profile scoreboard/];

sub run {
    my $self    = shift;
    local $Workman::Server::Util::SIGNAL_HANDLER = $self->set_signal_handler();

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
    $SIG{$_} = 'IGNORE' for qw/INT/;

    my $handler = Workman::Server::SignalHandler->new;
    $handler->register($_ => sub { $self->shutdown($_) }) for qw/TERM HUP/;
    $handler->register($_ => sub { $self->abort($_)    }) for qw/ABRT/;

    return $handler;
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
