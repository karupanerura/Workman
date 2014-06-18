package Workman::Queue::Qudo;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite ro => [qw/qudo/];

use Qudo;
use Workman::Job;
use Workman::Request;

sub new {
    my $class = shift;
    my $qudo  = Qudo->new(@_);
    return $class->SUPER::new(qudo => $qudo);
}

sub register_tasks {
    my ($self, $task_set) = @_;
    $self->qudo->manager->register_abilities($task_set->get_all_task_names);
}

sub enqueue {
    my ($self, $name, $args) = @_;
    $self->qudo->enqueue($name, $args);
    return Workman::Request->new(
        on_wait => sub {
            warn "[$$] Q4M hasn't support to wait result.";
            return;
        },
    );
}

sub dequeue {
    my $self    = shift;
    my $manager = $self->qudo->manager;

    my $job = $manager->find_job;
    return unless $job;

    my $name = $job->funcname;
    return unless $name;

    $manager->call_hook('deserialize', $job);
    $manager->call_hook('pre_work',    $job);
    return Workman::Job->new(
        name    => $name,
        args    => $job->arg,
        on_done => sub {
            my $result = shift;
            warn "[$$] Qudo hasn't support to send result." if defined $result;
            $manager->call_hook('post_work', $job);
            $job->completed();
        },
        on_abort => sub {
            my $e = shift;
            $manager->call_hook('post_work', $job);
            $job->abort($e);
        },
    );
}

sub dequeue_abort {}

1;
__END__
