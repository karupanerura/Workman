package Workman::Test::Queue;
use strict;
use warnings;
use utf8;

use Test::Builder;
use Test::Differences ();
use Test::SharedFork 0.28;
use Proc::Guard ();
use Sys::SigAction qw/set_sig_handler timeout_call/;
use POSIX qw/SA_RESTART/;
use Time::HiRes;
use Workman::Task;
use Workman::Task::Set;
use Workman::Test::Shared;
use JSON::XS;
use Try::Tiny;
use List::Util qw/sum/;

use Class::Accessor::Lite ro => [qw/queue taskset t json/], rw => [qw/verbose/];
sub new {
    my ($class, $queue) = @_;

    my $taskset = Workman::Task::Set->new->add_task(
        Workman::Task->new(Foo => sub {})
    )->add_task(
        Workman::Task->new(Bar => sub {})
    );

    return bless {
        queue   => $queue,
        taskset => $taskset,
        verbose => $ENV{TRAVIS} ? 1 : 0,
        t       => Test::Builder->new,
        json    => JSON::XS->new->ascii->canonical->allow_nonref->allow_blessed,
    } => $class;
}

sub plans {
    my $self = shift;

    my @plans = (
       { name => 'isa',            tests => 1 },
       { name => 'enqueue',        tests => 1 },
       { name => 'register_tasks', tests => 1 },
       { name => 'dequeue',        tests => 4 },
    );
    if ($self->queue->can_wait_job && !$self->queue->isa('Workman::Queue::Mock')) {
        push @plans => { name => 'parallel', tests => 151 };
    }
    return @plans;
}

sub run {
    my $self = shift;

    my @plans = $self->plans;
    my $tests = sum map { $_->{tests} } @plans;
    $self->t->plan(tests => $tests);
    for my $category (@plans) {
        my $method = sprintf 'check_%s', $category->{name};
        $self->$method();
    }
}

my $VERBOSE_METHOD = $ENV{TRAVIS} ? 'diag' : 'note';
sub _verbose_log {
    my $self = shift;
    return unless $self->verbose;

    my ($pkg, undef, $line) = caller;
    my @msg = $self->t->explain(@_);
    $self->t->$VERBOSE_METHOD("[$$] VERBOSE: $pkg:L$line: @msg");
}

sub check_isa {
    my $self = shift;
    $self->_verbose_log($self->queue);
    $self->t->ok($self->queue->isa('Workman::Queue'), 'should extend Workman::Queue');
}

sub check_register_tasks {
    my $self = shift;

    local $@;
    eval {
        $self->_verbose_log($self->taskset);
        $self->queue->register_tasks($self->taskset);
    };
    $self->t->is_eq($@, '', 'sould be live');
}

sub check_enqueue {
    my $self = shift;
    my $req  = $self->queue->enqueue(Foo => { id => 1 });
    $self->_verbose_log($req);
    $self->t->ok($req->isa('Workman::Request'), 'should extend Workman::Request');
}

sub check_dequeue {
    my $self = shift;
    my $job;
    timeout_call 3 => sub {
        $job = $self->queue->dequeue() until defined $job;
    };
    $self->_verbose_log($job);
    $self->t->ok($job->isa('Workman::Job'), 'should extend Workman::Job');
    $self->t->is_eq($job->name, 'Foo', 'should fetch Foo');
    $self->_is_deeply($job->args, { id => 1 }, 'should fetch');
    $job->done();

    undef $job;
    timeout_call 3 => sub {
        $job = $self->queue->dequeue();
    };
    $self->_verbose_log($job);
    $self->t->is_eq($job, undef, 'should be empty');
}

sub _is_deeply {
    my ($self, $got, $expected, $msg) = @_;
    Test::Differences::eq_or_diff($got, $expected, $msg);
}

sub check_parallel {
    my $self = shift;

    my $shared = Workman::Test::Shared->new(0);

    my @guard;
    for my $num (1..10) {
        push @guard => Proc::Guard->new(code => sub {
            my $stop = 0;
            set_sig_handler('TERM', sub {
                $self->t->note("[$$] SIGTERM RECEIVED");
                $stop = 1;
                $self->queue->dequeue_abort();
            }, {
                flags => SA_RESTART
            });

            until ($stop) {
                my $job = try {
                    $self->queue->dequeue();
                }
                catch {
                    $self->t->note($_);
                    undef;
                };
                next unless defined $job;

                $self->_verbose_log($job);

                $shared->txn(sub {
                    my $c = shift;
                    $c++;
                    $self->_verbose_log($c);
                    return $c;
                });

                my $id = $job->args->{id};
                if ($id % 2 == 0) {
                    $job->done({
                        num => $num,
                        id  => $id,
                    });
                }
                else {
                    $job->fail();
                }
            } continue { Time::HiRes::sleep 0.1 }
        });
    }

    for my $id (1..100) {
        push @guard => Proc::Guard->new(code => sub {
            local $SIG{TERM} = 'IGNORE';
            sleep 1;
            my $req = $self->queue->enqueue(Foo => { id => $id });
            $self->_verbose_log($req);
            if (my $res = $req->wait) {
                $self->t->ok($id % 2 == 0, 'should be complete.');
                $self->t->is_num($res->{id}, $id, 'should fetch result.');
            }
            else {
                $self->t->ok($id % 2 == 1, 'should be failed.');
            }
        });
    }

    my $is_timeout = timeout_call 30 => sub {
        my $c = 0;
        until ($c == 100) {
            $shared->txn(sub { $c = shift });
        } continue { sleep 1 }
        undef @guard;
        $self->t->ok(1, 'complete');
    };
    $self->t->ok(0, 'timeout') if $is_timeout;
}

1;
__END__

=encoding utf-8

=head1 NAME

Workman::Test::Queue - provide testing cases for Workman::Queue

=head1 SYNOPSIS

    #!perl
    use strict;
    use warnings;

    use Test::More;
    use Workman::Queue::Mock;
    use Workman::Test::Queue;

    my $queue = Workman::Queue::Mock->new;
    my $test  = Workman::Test::Queue->new($queue);

    $test->run;

    done_testing;

=head1 DESCRIPTION

Workman::Test::Queue provide testing cases for Workman.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

