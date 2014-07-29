package Workman::Server::Worker::Mock;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Server::Worker/;

use Class::Accessor::Lite
    rw => [qw/harakiri/],
    ro => [qw/on_start on_loop on_finish on_shutdown on_abort/];

use Workman::Server::Util qw/safe_sleep/;

sub _run {
    my $self = shift;

    $self->on_start->($self) if defined $self->on_start;
    until ($self->harakiri) {
        $self->on_loop->($self) if defined $self->on_loop;
        safe_sleep;
    }
    $self->on_finish->($self) if defined $self->on_finish;
}

# override
sub shutdown :method {
    my ($self, $sig) = @_;
    $self->harakiri(1);
    $self->on_shutdown->($self) if defined $self->on_shutdown;
}

# override
sub abort {
    my ($self, $sig) = @_;
    $self->harakiri(1);
    $self->on_abort->($self) if defined $self->on_abort;
}

1;
__END__
