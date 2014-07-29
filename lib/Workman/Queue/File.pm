package Workman::Queue::File;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite
    ro => [qw/file/];

use Fcntl qw/:flock/;
use POSIX qw/mkfifo/;
use Workman::Request;
use Workman::Job;
use Workman::Server::Util qw/safe_sleep/;
use JSON::XS;
use File::Spec;
use File::Basename qw/dirname/;
use File::Path 2.00 qw/make_path/;

use constant RESULT_TAG_DONE  => 'done';
use constant RESULT_TAG_ABORT => 'abort';

sub register_tasks {} # not needed

sub json {
    my $self = shift;
    return $self->{json} ||= JSON::XS->new->utf8;
}

sub _write_queue {
    my ($self, $msg) = @_;
    my $file = $self->file;
    open my $fh, '>>', $file or die "failed to open file: $file: $!";
    flock $fh, LOCK_EX;
    syswrite $fh, "$msg$/";
    flock $fh, LOCK_UN;
    close $fh;
}

sub _read_queue {
    my $self = shift;
    my $file = $self->file;

    open my $fh, '+<', $file or return;
    flock $fh, LOCK_EX;
    my $msg = <$fh>;
    my $que = do { local $/; <$fh> };
    seek $fh, 0, 0;
    truncate $fh, 0;
    syswrite $fh, $que if $que;
    flock $fh, LOCK_UN;
    close $fh;

    return $msg;
}

sub enqueue {
    my ($self, $name, $args) = @_;

    my $fifo = File::Spec->catfile(
        File::Spec->tmpdir,
        $$,
        int(rand time)."_${name}_".time,
    );
    make_path(dirname($fifo));
    mkfifo($fifo, 0777) or die $!;

    my $msg = $self->json->encode([$name, $args, $fifo]);
    $self->_write_queue($msg);
    return Workman::Request->new(
        on_wait => sub {
            open my $fh, '<', $fifo or die $!;
            my $result = <$fh>;
            close $fh;
            unlink $fifo;

            $result = $self->json->decode($result);
            my ($tag, $res) = @$result;
            die $res if $tag eq RESULT_TAG_ABORT;
            return $res;
        },
        on_background => sub {
            unlink $fifo;
        },
    );

}

sub dequeue {
    my $self = shift;
    my $json = $self->_read_queue() or return;

    my $job = $self->json->decode($json);
    my ($name, $args, $fifo) = @$job;
    return Workman::Job->new(
        name     => $name,
        args     => $args,
        on_done  => sub {
            my $result = shift;

            open my $fh, '>', $fifo or return;
            syswrite $fh, $self->json->encode([RESULT_TAG_DONE, $result]);
            close $fh;
        },
        on_abort => sub {
            my $e = shift;

            open my $fh, '>', $fifo or return;
            syswrite $fh, $self->json->encode([RESULT_TAG_ABORT, $e]);
            close $fh;
        },
    );
}

sub dequeue_abort {}

1;
__END__
