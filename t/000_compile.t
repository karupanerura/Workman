use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Workman
    Workman::Client
    Workman::Job
    Workman::Queue
    Workman::Queue::File
    Workman::Queue::Mock
    Workman::Request
    Workman::Server
    Workman::Server::Exception
    Workman::Server::Exception::DequeueAbort
    Workman::Server::Exception::TaskAbort
    Workman::Server::Exception::TaskAbort::ForceKilled
    Workman::Server::Exception::TaskNotFound
    Workman::Server::Profile
    Workman::Server::SignalHandler
    Workman::Server::Util
    Workman::Server::Worker
    Workman::Server::Worker::Admin
    Workman::Server::Worker::Job
    Workman::Server::Worker::Mock
    Workman::Task
    Workman::Task::Class
    Workman::Task::Set
    Workman::Test::Queue
    Workman::Test::Shared
);

done_testing;

