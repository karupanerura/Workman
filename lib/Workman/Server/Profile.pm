package Workman::Server::Profile;
use strict;
use warnings;
use utf8;

use Workman::Task::Set;

use Class::Accessor::Lite
    ro  => [
        qw/
              queue
              max_workers
              spawn_interval
              max_reqs_par_child
              graceful_shutdown_timeout
              dequeue_interval
              admin_port
        /
    ];

sub new {
    my $class = shift;
    my $args  = (@_ == 1 and ref $_[0] eq 'HASH') ? +shift : {@_};
    return bless +{
        max_workers               => 1,
        spawn_interval            => 0,
        max_reqs_par_child        => 100,
        graceful_shutdown_timeout => 20,
        dequeue_interval          => 0,
        admin_port                => 8989,
        %$args,
    } => $class;
}

sub set_task_loader {
    my ($self, $task_loader) = @_;
    $self->{_task_loader} = $task_loader;
    return $self;
}

sub load_task {
    my $self = shift;
    my $set = Workman::Task::Set->new;
    $self->{_task_loader}->($set);
    return $set;
}

1;
