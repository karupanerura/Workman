package Workman::Queue;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite new => 1;

sub register_tasks { die "this is abstract method." }
sub enqueue        { die "this is abstract method." }
sub dequeue        { die "this is abstract method." }
sub wait_abort     { die "this is abstract method." }

1;
__END__
