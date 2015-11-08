[![Build Status](https://travis-ci.org/karupanerura/Workman.svg?branch=master)](https://travis-ci.org/karupanerura/Workman) [![Coverage Status](https://img.shields.io/coveralls/karupanerura/Workman/master.svg?style=flat)](https://coveralls.io/r/karupanerura/Workman?branch=master)
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

Workman is light weight job-queue worker framework.

## FEATURES

### UNIX SIGNALS HANDLING SUPPORT

UNIX signals handling is needed to manage worker status. (e.g. shutdown, restart, etc..)
So it's a very important probolem. but, it's very difficult to a lot of application engineers. (also it's difficult to test.)
Workman support UNIX signals management as easily and safely. Workman's signal handling code is covered in testing cases.

### INTERCHANGEABLE

A lot of job-queue engines exists in the world.
But, some application developpers cannot select job-queue engine as the case may be.
There want to change job-queue engines easily, and don't want to change my code.
Workman support to change job-queue engines easily, and change a little my code.

### PLUGGABLE

Workman supports some job-queue engines (e.g. Q4M, Gearman, etc..), but we can manage job-queue engines in same interface on Workman.
If you want to write [Workman::Queue](https://metacpan.org/pod/Workman::Queue) sub-class, don't worry.
We provided testing cases as a module. SEE ALSO: [Workman::Test::Queue](https://metacpan.org/pod/Workman::Test::Queue)

# SEE ALSO

[Workman::Queue](https://metacpan.org/pod/Workman::Queue)
[Workman::Client](https://metacpan.org/pod/Workman::Client)
[Workman::Server](https://metacpan.org/pod/Workman::Server)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura &lt;karupa@cpan.org>
