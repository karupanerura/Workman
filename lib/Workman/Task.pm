package Workman::Task;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite
    new => 1,
    ro  => [qw/name code/];

sub run {
    my $self = shift;
    $self->{count}++;

    local $0 = sprintf '%s [RUN:%s]', $0, $self->name;
    return $self->work_job(@_);
}

sub work_job { shift->code->(@_) }

1;
__END__
