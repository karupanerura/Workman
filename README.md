# NAME

Workman - light weight job-queue worker framework

# SYNOPSIS

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

# DESCRIPTION

Workman is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
