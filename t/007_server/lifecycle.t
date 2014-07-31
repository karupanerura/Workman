use strict;
use warnings;
use Test::More tests => 68;

BEGIN {
    *CORE::GLOBAL::fork = \&_fork;
}

use Test::SharedFork 0.28;
use Test::TCP ();
use t::Util;

use Workman::Queue::Mock;
use Workman::Server::Profile;
use Workman::Server;
use Workman::Server::Worker::Mock;
use Workman::Server::Worker::Job;
use Workman::Test::Shared;

our $PID_MAP_SHARED = Workman::Test::Shared->new({});

run();
exit 0;

sub _fork {
    my $pid = CORE::fork;
    if ($pid) {
        $PID_MAP_SHARED->txn(sub {
            my $map = shift;
            $map->{$$}->{$pid} = 'unknown';
            return $map;
        });
    }
    return $pid;
}

END {
    $PID_MAP_SHARED->txn(sub {
        my $map = shift;
        delete $map->{getppid()}->{$$};
        return $map;
    });
}

sub run {
    my $worker = Test::TCP->new(code => \&worker);
    sleep 3; # wait while ready

    my $pid = $worker->pid;
    ok kill(0, $pid), "should live parent. pid:$pid";
    my (@pids, $admin_worker_pid);
    $PID_MAP_SHARED->txn(sub {
        my $map = shift;
        @pids = keys %{ $map->{$pid} };
        ($admin_worker_pid) = grep { $map->{$pid}->{$_} ne 'job' } @pids;
        return $map;
    });
    ok kill(0, $_), "should lived child. pid:$_" for @pids;
    is scalar @pids, 6, 'should create 5 job workers and one admin worker.';

    kill HUP => $pid;
    sleep 5;

    my @new_pids;
    $PID_MAP_SHARED->txn(sub {
        my $map = shift;
        @new_pids = keys %{ $map->{$pid} };
        return $map;
    });
    ok !kill(0, $_), "should not lived old job workers. pid:$_" for grep { $admin_worker_pid != $_ } @pids;
    ok  kill(0, $_), "should lived new child. pid:$_" for @new_pids;

    $worker->stop;
    sleep 5;

    ok !kill(0, $pid), "should not lived parent.";
    ok !kill(0, $_),   "should not lived old child. pid:$_" for @pids;
    ok !kill(0, $_),   "should not lived new child. pid:$_" for @new_pids;
}

sub worker {
    my $admin_port = shift;
    my $parent_pid = $$;

    no warnings qw/redefine once/;
    my $shared = Workman::Test::Shared->new(0);
    local *Workman::Server::Worker::Job::new = sub {
        my ($expect_shutdown, $expect_abort, $expect_finish);
        Workman::Server::Worker::Mock->new(
            on_start => sub {
                my $worker = shift;
                $shared->txn(sub {
                    my $c = shift;
                    ($expect_shutdown, $expect_abort, $expect_finish) = (0, $c % 2, 0);
                    return ++$c;
                });
                $PID_MAP_SHARED->txn(sub {
                    my $map = shift;
                    $map->{getppid()}->{$$} = 'job';
                    return $map;
                });

                note "$$: $expect_shutdown, $expect_abort, $expect_finish";
                is getppid(), $parent_pid, 'should start in child process';
            },
            on_loop => sub {
                $expect_shutdown = 1;
            },
            on_shutdown => sub {
                my $worker = shift;
                ok $expect_shutdown, 'should shutdown';
                if ($expect_abort) {
                    $worker->harakiri(0);
                }
                else {
                    $expect_finish = 1;
                }
            },
            on_abort => sub {
                my $worker = shift;
                ok $expect_abort, 'should force shutdown';
                $expect_finish = 1;
            },
            on_finish => sub {
                my $worker = shift;
                ok $expect_finish, 'should finish worker';
            },
        );
    };
    use warnings qw/redefine once/;

    my $profile = Workman::Server::Profile->new(
        queue                     => Workman::Queue::Mock->new,
        admin_port                => $admin_port,
        max_workers               => 5,
        graceful_shutdown_timeout => 2,
    );

    my $server = Workman::Server->new(profile => $profile);
    isa_ok $server, 'Workman::Server';

    $server->run;

    $PID_MAP_SHARED->txn(sub {
        my $map = shift;
        ok kill(0, $_), "should not lived child. pid:$_" for keys %{ $map->{$$} };
        return $map;
    });

    exit 0;
}
