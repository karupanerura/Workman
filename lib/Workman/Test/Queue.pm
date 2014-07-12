package Workman::Test::Queue;
use strict;
use warnings;
use utf8;

use Test::Builder;
use Test::SharedFork 0.28;
use Proc::Guard ();
use Sys::SigAction qw/set_sig_handler/;
use POSIX qw/SA_RESTART/;
use Time::HiRes;
use Workman::Task;
use Workman::Task::Set;
use JSON::XS;
use Try::Tiny;
use Fcntl qw/:flock/;
use File::Temp qw/tempfile/;

use Class::Accessor::Lite ro => [qw/queue taskset t json/];
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
        t       => Test::Builder->new,
        json    => JSON::XS->new->ascii->canonical->allow_nonref->allow_blessed,
    } => $class;
}

sub plans {
    my $self = shift;

    my @plans = qw/
       isa
       register_tasks
       enqueue
       dequeue
    /;
    if ($self->queue->can_wait_job && !$self->queue->isa('Workman::Queue::Mock')) {
        push @plans => 'parallel';
    }
    return @plans;
}

sub run {
    my $self = shift;

    for my $category ($self->plans) {
        my $method = sprintf 'check_%s', $category;
        $self->t->subtest("check $category" => sub { $self->$method() });
    }
}

sub check_isa {
    my $self = shift;
    $self->t->ok($self->queue->isa('Workman::Queue'), 'should extend Workman::Queue');
}

sub check_register_tasks {
    my $self = shift;

    local $@;
    eval {
        $self->queue->register_tasks($self->taskset);
    };
    $self->t->is_eq($@, '', 'sould be live');
}

sub check_enqueue {
    my $self = shift;
    my $req  = $self->queue->enqueue(Foo => { this => { is => 'foo args' } });
    $self->t->ok($req->isa('Workman::Request'), 'should extend Workman::Request');
}

sub check_dequeue {
    my $self = shift;
    my $job  = $self->queue->dequeue();
    $self->t->ok($job->isa('Workman::Job'), 'should extend Workman::Job');
    $self->t->is_eq($job->name, 'Foo', 'should fetch Foo');
    $self->_is_deeply($job->args, { this => { is => 'foo args' } }, 'should fetch');
    $job->done();

    $job = $self->queue->dequeue();
    $self->t->is_eq($job, undef, 'should be empty');
}

sub _is_deeply {
    my ($self, $got, $expected, $msg) = @_;
    $self->t->is_eq(
        $self->json->encode($got),
        $self->json->encode($expected),
        $msg
    );
}

sub check_parallel {
    my $self = shift;

    $self->t->plan(tests => 100);

    my ($fh, $filename) = tempfile();
    syswrite $fh, '0', 1;

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

                open my $fh, '+<', $filename or die "failed to open temporary file: $filename: $!";
                flock $fh, LOCK_EX;
                sysread $fh, my $c, 10;
                $c++;
                seek $fh, 0, 0;
                syswrite $fh, $c, length $c;
                flock $fh, LOCK_UN;
                close $fh;

                my $id = $job->args->{id};
                if ($id % $num == 0) {
                    $job->done({
                        num => $num,
                        id  => $id,
                    });
                }
                else {
                    $job->abort({ num => $num });
                }
            } continue { Time::HiRes::sleep 0.1 }
        });
    }

    for my $id (1..100) {
        push @guard => Proc::Guard->new(code => sub {
            local $SIG{TERM} = 'IGNORE';
            sleep 1;
            my $req = $self->queue->enqueue(Foo => { id => $id });
            try {
                my $res = $req->wait;
                $self->t->is_num($res->{id}, $id, 'should fetch result.');
            } catch {
                my $e = $_;
                $self->t->ok($id % $e->{num}, 'okay retry');
            };
        });
    }

    my $is_timeout = 0;
    try {
        local $SIG{ALRM} = sub {
            $is_timeout = 1;
            die "timeout";
        };
        alarm 20;
        while (1) {
            flock $fh, LOCK_EX;
            seek $fh, 0, 0;
            sysread $fh, my $c, 10;
            flock $fh, LOCK_UN;
            if ($c == 100) {
                undef @guard;
                $self->t->note('complete');
                last;
            }
            sleep 1;
        }
        alarm 0;
    }
    catch {
        $self->t->ok(0, 'timeout') if $is_timeout;
        die $_ unless $is_timeout;
    };
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

