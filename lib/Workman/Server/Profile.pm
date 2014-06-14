package Workman::Server::Profile;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite
    ro  => [
        qw/
              queue
              max_workers
              max_reqs_par_child
              graceful_shutdown_timeout
              wait_interval
              admin_port
        /
    ];

sub new {
    my $class = shift;
    my $args  = (@_ == 1 and ref $_[0] eq 'HASH') ? +shift : {@_};
    return bless +{
        max_workers               => 1,
        max_reqs_par_child        => 100,
        graceful_shutdown_timeout => 20,
        wait_interval             => 0.1,
        admin_port                => 8989,
        %$args,
    } => $class;
}

sub register {
    my ($self, $task_register) = @_;
    $self->{_task_register} = $task_register;
    return $self;
}

sub apply {
    my ($self, $worker) = @_;
    $self->{_task_register}->($worker);
    return $worker;
}

1;
