package Workman::Job;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite
    new => 1,
    ro  => [qw/name args on_done on_abort/];

sub done {
    my ($self, $result) = @_;
    $self->on_done->($result) if $self->on_done;
}

sub abort {
    my ($self, $e) = @_;
    $self->on_abort->($e) if $self->on_abort;
}

1;
__END__
