package Workman::Queue::Mock;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite rw => [qw/on_wait on_background on_done on_abort on_dequeue_abort/];

use Workman::Request;
use Workman::Job;

sub register_tasks {
    my $self = shift;
    my %task = map { $_->name => $_ } @_;
    $self->{task} = \%task;
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

    my $job  = pop @{ $self->{queue} } or return;
    my ($name, $args) = @$job;
    return Workman::Job->new(
        name     => $name,
        args     => $args,
        on_done  => $self->on_done,
        on_abort => $self->on_abort,
    );
}

sub dequeue_abort {
    my $self = shift;
    $self->on_dequeue_abort->() if defined $self->on_dequeue_abort;
}

1;
__END__