package Workman::Server::Profile;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite
    new => 1,
    ro  => [
        qw/
              queue
              max_workers
              max_reqs_par_child
              graceful_shutdown_timeout
              admin_port
        /
    ];

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
