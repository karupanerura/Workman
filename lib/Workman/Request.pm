package Workman::Request;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite
    new => 1,
    ro  => [qw/on_wait on_background/],
    rw  => [qw/done/];

sub wait :method {
    my $self = shift;
    $self->done(1);

    return unless $self->on_wait;
    return $self->on_wait->();
}

sub background {
    my $self = shift;
    $self->done(1);

    if ($self->on_background) {
        $self->on_background->();
    }
    return;
}

sub DESTROY {
    my $self = shift;
    return if $self->done;
    $self->done(1);

    $self->background();
}

1;
__END__
