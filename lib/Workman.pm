package Workman;
use strict;
use warnings;
use utf8;
use v5.8.1;

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
    use Workman::Queue::Gearman;
    use Workman::Task;

    my $queue   = Workman::Queue::Gearman->new(job_servers => [...]);
    my $profile = Workman::Server::Profile->new(max_workers => 10, queue => $queue);
    $profile->set_task_loader(sub {
        my $set = shift;

        warn "[$$] register tasks...";
        my $task = Workman::Task->new(Echo => sub {
            my $args = shift;
            warn $args->{message};
            return $args;
        });
        $set->add($task);
    });

    # start
    Workman::Server->new(profile => $profile)->run();

    ########## client.pl ##########
    use Workman::Client;
    use Workman::Queue::Gearman;

    my $queue  = Workman::Queue::Gearman->new(job_servers => [...]);
    my $client = Workman::Client->new(queue => $queue);

    my $job    = $client->enqueue(Echo => { message => 'hello!!' });
    my $result = $job->wait;

=head1 DESCRIPTION

Workman is light weight job-queue worker framework.

=head2 FEATURES

=head3 UNIX SIGNALS HANDLING SUPPORT

UNIX signals handling is needed to manage worker status. (e.g. shutdown, restart, etc..)
So it's a very important probolem. but, it's very difficult to a lot of application engineers. (also it's difficult to test.)
Workman support UNIX signals management as easily and safely. Workman's signal handling code is covered in testing cases.

=head3 INTERCHANGEABLE

A lot of job-queue engines exists in the world.
But, some application developpers cannot select job-queue engine as the case may be.
There want to change job-queue engines easily, and don't want to change my code.
Workman support to change job-queue engines easily, and change a little my code.

=head3 PLUGGABLE

Workman supports some job-queue engines (e.g. Q4M, Gearman, etc..), but we can manage job-queue engines in same interface on Workman.
If you want to write L<Workman::Queue> sub-class, don't worry.
We provided testing cases as a module. SEE ALSO: L<Workman::Test::Queue>

=head1 SEE ALSO

L<Workman::Queue>
L<Workman::Client>
L<Workman::Server>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

