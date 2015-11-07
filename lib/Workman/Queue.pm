package Workman::Queue;
use strict;
use warnings;
use utf8;

use Carp ();

use Class::Accessor::Lite new => 1;

sub can_wait_job   { 1 }
sub register_tasks { Carp::croak "this is abstract method." }
sub enqueue        { Carp::croak "this is abstract method." }
sub dequeue        { Carp::croak "this is abstract method." }
sub dequeue_abort  { Carp::croak "this is abstract method." }

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Queue - abstract class of queue module

=head1 DESCRIPTION

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

