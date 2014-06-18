use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Workman
    Workman::Task
    Workman::Client
    Workman::Request
    Workman::Server
    Workman::Server::Worker::Job
    Workman::Server::Worker::Admin
    Workman::Server::Profile
    Workman::Server::Exception
    Workman::Server::Exception::TaskNotFound
    Workman::Job
    Workman::Queue
    Workman::Queue::Q4M
    Workman::Queue::Gearman
    Workman::Queue::Qudo
);

done_testing;

