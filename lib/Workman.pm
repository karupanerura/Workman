package Workman;
use strict;
use warnings;
use utf8;

our $VERSION = "0.01";

1;
__END__

=encoding utf-8

=head1 NAME

Workman - light weight job-queue worker framework

=head1 SYNOPSIS

    ########## worker.pl ##########
    use Workman::Server;
    use Workman::Server::Profile;
    use Workman::Queue::Q4M;
    use Workman::Task;

    my $queue   = Workman::Queue::Q4M->new(dsn => [...]);
    my $profile = Workman::Server::Profile->new(max_workers => 10, queue => $queue);
    $profile->register(sub {
        my $worker = shift;

        my $task = Workman::Task->new(Echo => sub {
            my $args = shift;
            warn $args->{message};
            return $args;
        });
        $worker->register_task($task);
    });

    # start
    Workman::Server->new(profile => $profile)->run();

    ########## client.pl ##########
    use Workman::Client;
    use Workman::Queue::Q4M;

    my $queue  = Workman::Queue::Q4M->new(dsn => [...]);
    my $client = Workman::Client->new(queue => $queue);

    my $job    = $client->enqueue(Echo => { message => 'hello!!' });
    my $result = $job->wait;

=head1 DESCRIPTION

Workman is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

