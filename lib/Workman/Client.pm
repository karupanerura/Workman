package Workman::Client;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite new => 1, ro => [qw/queue/];

use Try::Tiny;

sub enqueue {
    my ($self, $name, $args, $opt) = @_;
    $opt ||= {};
    return $self->queue->enqueue($name, $args);
}

sub enqueue_background {
    my $self = shift;
    $self->enqueue(@_);
    return;
}

sub enqueue_with_wait {
    my ($self, $name, $args, $opt) = @_;
    $opt ||= {};
    if (exists $opt->{on_abort}) {
	my $on_abort = delete $opt->{on_abort};
	return try {
            $self->enqueue_with_wait($name, $args, $opt);
	}
	catch {
            $on_abort->($_);
	};
    }
    return $self->enqueue($name, $args, $opt)->wait;
}

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Client - job-queue worker client

=head1 SYNOPSIS

     use Workman::Client;

=head1 DESCRIPTION

Workman is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

