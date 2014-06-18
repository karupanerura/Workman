package Workman::Task::Set;
use strict;
use warnings;
use utf8;

use Module::Load qw/load/;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use Class::Accessor::Lite new => 1;

sub add {
    my $self = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    for my $task (@_) {
        if (blessed $task && $task->isa('Workman::Task::Set')) {
            $self->merge($task);
        }
        elsif (blessed $task && $task->isa('Workman::Task')) {
            $self->add_task($task);
        }
        else {
            $self->add_class($task);
        }
    }

    return $self;
}

sub exists :method {
    my ($self, $name) = @_;
    return exists $self->{_task}->{$name};
}

sub add_task {
    my $self = shift;
    for my $task (@_) {
        my $name = $task->name;
        croak "task already registerd. name: $name" if exists $self->{_task}->{$name};
        $self->{_task}->{$name} = $task;
    }
    return $self;
}

sub add_class {
    my $self = shift;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    for my $task_class (@_) {
        load($task_class);
        $self->add_task($task_class->new);
    }

    return $self;
}

sub get_task {
    my ($self, $name) = @_;
    return unless exists $self->{_task}->{$name};
    return $self->{_task}->{$name};
}

sub get_all_tasks {
    my $self = shift;
    return values %{ $self->{_task} };
}

sub get_all_task_names {
    my $self = shift;
    return keys %{ $self->{_task} };
}

sub clear {
    my $self = shift;
    $self->{_task} = {};
    return $self;
}

sub clone {
    my $self = shift;
    my $class  = ref $self;
    my $task   = $self->{_task} || {};
    return $class->new(_task => { %$task });
}

sub merge {
    my ($self, $task_set) = @_;

    local $Carp::CarpLevel = $Carp::CarpLevel + 1;
    return $self->add_task($task_set->get_all_tasks);
}

1;
__END__
