package Workman::Task;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite ro  => [qw/name code/];

sub new {
    my ($class, $name, $code) = @_;
    return bless +{
        name => $name,
        code => $code,
    } => $class;
}

sub run {
    my ($self, $args) = @_;
    $self->{count}++;

    local $0 = sprintf '%s [RUN:%s]', $0, $self->name;
    return $self->work_job($args);
}

sub work_job {
    my ($self, $args) = @_;
    return $self->code->($args);
}

1;
__END__
