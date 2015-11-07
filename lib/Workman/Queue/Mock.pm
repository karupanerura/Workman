package Workman::Queue::Mock;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite
    ro => [qw/task_set/],
    rw => [qw/on_wait on_background on_done on_fail on_abort on_dequeue_abort/];

use Workman::Request;
use Workman::Job;

sub register_tasks {
    my ($self, $task_set) = @_;
    $self->{task_set} = $task_set;
}

sub enqueue {
    my ($self, $name, $args) = @_;
    $self->{enqueue_count} = 0 unless exists $self->{enqueue_count};
    $self->{enqueue_count}++;

    push @{ $self->{queue} } => [$name, $args];
    return Workman::Request->new(
        on_wait       => $self->on_wait,
        on_background => $self->on_background,
    );

}

sub dequeue {
    my $self = shift;
    $self->{dequeue_count} = 0 unless exists $self->{dequeue_count};
    $self->{dequeue_count}++;

    my $job = shift @{ $self->{queue} } or return;
    my ($name, $args) = @$job;
    return Workman::Job->new(
        name     => $name,
        args     => $args,
        on_done  => $self->on_done,
        on_fail  => $self->on_fail,
        on_abort => $self->on_abort,
    );
}

sub dequeue_abort {
    my $self = shift;
    $self->on_dequeue_abort->() if defined $self->on_dequeue_abort;
}

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Queue::Mock - a mocking queue implementation

=head1 WARNING

DO *NOT* USE IT IN PRODUCTION.

=head1 DESCRIPTION

This is a mocking queue implementation.
You should use this module for testing or debbuging only.
If you want to use it, you should read this code before using.
So I don't write documents about interface specs in pod.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

