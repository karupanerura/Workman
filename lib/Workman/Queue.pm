package Workman::Queue;
use strict;
use warnings;
use utf8;

use Carp ();

use Class::Accessor::Lite new => 1, ro => [qw/role/];

sub can_wait_job   { 1 }
sub register_tasks { Carp::croak "this is abstract method." }
sub enqueue        { Carp::croak "this is abstract method." }
sub dequeue        { Carp::croak "this is abstract method." }
sub dequeue_abort  { Carp::croak "this is abstract method." }

1;
__END__
