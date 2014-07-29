package t::Task::Foo;
use strict;
use warnings;
use parent qw/Workman::Task::Class/;

our $ARGS;
our $COUNT = 0;

sub work_job {
    my ($self, $args) = @_;
    $ARGS = $args;
    $COUNT++;
    return { it => { is => 'result', count => $COUNT } };
}

1;
