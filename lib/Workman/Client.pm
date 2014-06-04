package Workman::Client;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite new => 1, ro => [qw/queue/];

sub enqueue {
    my $self = shift;
    return $self->queue->enqueue(@_);
}

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Client - job-queue worker client

=head1 SYNOPSIS


=head1 DESCRIPTION

Workman is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

