package Workman::Task;
use strict;
use warnings;
use utf8;

use overload
    '""' => 'name',
    fallback => 1;

use Class::Accessor::Lite ro => [qw/code count/],
                          rw => [qw/on_start on_done on_fail on_abort/];

use Log::Minimal qw/infof warnf/;

sub new {
    my ($class, $name, $code) = @_;
    return bless +{
        name  => $name,
        code  => $code,
        count => 0,
    } => $class;
}

sub name {
    my $invocant = shift;
    return $invocant->{name} if ref $invocant;
    return $invocant;
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
    infof '[%d] START JOB: %s', $$, $self->name;
    $self->on_start->($self) if $self->on_start;
}

sub event_done {
    my $self = shift;
    infof '[%d] FINISH JOB: %s', $$, $self->name;
    $self->on_done->($self) if $self->on_done;
}

sub event_fail {
    my ($self, $e) = @_;
    my $name  = $self->name;
    my $count = $self->count;
    warnf '[%d] FAIL JOB: %s (count:%d) Error:%s', $$, $name, $count, "$e";
    $self->on_fail->($self, $e) if $self->on_fail;
}

sub event_abort {
    my ($self, $e) = @_;
    my $name  = $self->name;
    my $count = $self->count;
    warnf '[%d] ABORT JOB: %s (count:%d) Error:%s', $$, $name, $count, "$e";
    $self->on_abort->($self, $e) if $self->on_abort;
}

1;
__END__
