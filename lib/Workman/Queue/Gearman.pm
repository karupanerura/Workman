package Workman::Queue::Gearman;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite ro => [qw/prefix job_servers/];

use AnyEvent;
use AnyEvent::Gearman::Client;
use AnyEvent::Gearman::Worker;
use Workman::Job;
use Workman::Request;
use JSON::XS;

sub _json {
    my $self = shift;
    return $self->{_json} ||= JSON::XS->new->utf8;
}

sub register_tasks {
    my ($self, $task_set) = @_;

    if (exists $self->{gearman}) {
        warn "[$$] workers already registerd to gearmand.";
        return;
    }

    my $gearman = $self->{gearman} = AnyEvent::Gearman::Worker->new(
        job_servers => [@{ $self->job_servers }],
        $self->prefix ? (
            prefix => $self->prefix,
        ) : (),
    );

    for my $name ($task_set->get_all_task_names) {
        $gearman->register_function($name => sub {
            my $job  = shift;
            my $args = $self->_inflate($job->workload);
            $self->_send_job(
                Workman::Job->new(
                    name    => $name,
                    args    => $args,
                    on_done => sub {
                        my $result = shift;
                           $result = $self->_deflate($result);
                        $job->complete($result);
                    },
                    on_abort => sub {
                        my $e = shift;
                        $job->warning($e);
                        $job->fail;
                    },
                )
            );
        });
    }

    return;
}

sub enqueue {
    my ($self, $name, $args) = @_;
    my $workload = $self->_deflate($args);

    my $cv = AnyEvent->condvar;
    return Workman::Request->new(
        on_wait => sub {
            my $e;
            $self->_client->add_task(
                $name => $workload,
                on_complete => sub {
                    my (undef, $result) = @_;
                    $result = $self->_inflate($result);
                    $cv->send($result);
                },
                on_warning => sub {
                    (undef, $e) = @_;
                },
                on_fail => sub {
                    $cv->croak($e);
                },
            );
            return $cv->recv;
        },
        on_background => sub {
            $self->_client->add_task_bg(
                $name => $workload,
                on_created => sub { $cv->send },
            );
            $cv->recv;
        },
    );
}

sub dequeue { shift->_recv_job() }

sub dequeue_abort {
    my $self = shift;
    $self->{cv}->send() if $self->{cv};
}

sub _client {
    my $self = shift;
    return $self->{_client} ||= AnyEvent::Gearman::Client->new(
        job_servers => [@{ $self->job_servers }],
        $self->prefix ? (
            prefix => $self->prefix,
        ) : (),
    );
}

sub _send_job {
    my ($self, $job) = @_;
    $self->{cv}->send($job);
}

sub _recv_job {
    my $self = shift;
    local $self->{cv} = AnyEvent->condvar;
    return $self->{cv}->recv();
}

sub _inflate {
    my ($self, $workload) = @_;
    return $self->_json->decode($workload);
}

sub _deflate {
    my ($self, $args) = @_;
    return $self->_json->encode($args);
}

1;
__END__
