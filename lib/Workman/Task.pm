package Workman::Task;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite ro => [qw/name code count/],
                          rw => [qw/on_start on_done on_abort/];

use Log::Minimal qw/infof warnf/;

sub new {
    my ($class, $name, $code) = @_;
    return bless +{
        name  => $name,
        code  => $code,
        count => 0,
        on_start => sub {
            my $self = shift;
            infof '[%d] START JOB: %s', $$, $self->name;
        },
        on_done => sub {
            my $self = shift;
            infof '[%d] FINISH JOB: %s', $$, $self->name;
        },
        on_abort => sub {
            my ($self, $e) = @_;
            my $name  = $self->name;
            my $count = $self->count;
            warnf '[%d] ABORT JOB: %s (count:%d) Error:%s', $$, $name, $count, "$e";
        },
    } => $class;
}

sub run {
    my ($self, $args) = @_;
    $self->{count}++;

    local $0 = sprintf '%s [RUN:%s]', $0, $self->name;
    $self->event_start();
    my $result = $self->work_job($args);
    $self->event_done();
    return $result;
}

sub work_job {
    my ($self, $args) = @_;
    return $self->code->($args);
}

sub event_start {
    my $self = shift;
    $self->on_start->($self) if $self->on_start;
}

sub event_done {
    my $self = shift;
    $self->on_done->($self) if $self->on_done;
}

sub event_abort {
    my ($self, $e) = @_;
    $self->on_abort->($self, $e) if $self->on_abort;
}

1;
__END__
