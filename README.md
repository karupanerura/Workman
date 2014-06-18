[![Build Status](https://travis-ci.org/karupanerura/Workman.png?branch=master)](https://travis-ci.org/karupanerura/Workman) [![Coverage Status](https://coveralls.io/repos/karupanerura/Workman/badge.png?branch=master)](https://coveralls.io/r/karupanerura/Workman?branch=master)
# NAME

Workman - light weight job-queue worker framework

# SYNOPSIS

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

# DESCRIPTION

Workman is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
