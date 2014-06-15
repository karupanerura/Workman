package Workman::Queue::Q4M;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;
use Class::Accessor::Lite
    ro => [qw/dsn timeout/],
    rw => [qw/task_names/];

use DBIx::Sunny;
use SQL::Maker;

sub _dbh {
    my $self = shift;
    return $self->{_dbh} ||= DBIx::Sunny->connect(@{$self->dsn});
}

sub _sql_maker {
    my $self = shift;
    return $self->{_sql_maker} ||= SQL::Maker->new(driver => 'mysql');
}

sub register_tasks {
    my $self = shift;
    $self->task_names([map { $_->name } @_]);
}

sub enqueue {
    my ($self, $name, $args) = @_;
    my ($sql, @bind) = $self->_sql_maker->insert($name, $args);
    $self->dbh->query($sql, @bind);
    return Workman::Request->new(
        on_wait => sub {
            warn "[$$] Q4M hasn't support to wait result.";
            return;
        },
    );
}

sub dequeue {
    my $self = shift;

    my $index = do {
        my $args = [@{ $self->task_names }];
        push @$args => $self->timeout if defined $self->timeout;

        local $self->dbh->{private_in_queue_wait} = 1;
        $self->dbh->select_one('SELECT queue_wait(?)', $args);
    } or return;

    my $name = $self->task_names->[$index - 1];
    my $sql  = sprintf 'SELECT * FROM %s', $self->dbh->quote($name);
    my $args = $self->dbh->select_row($sql);
    return Workman::Job->new(
        name    => $name,
        args    => $args,
        on_done => sub {
            my $result = shift;
            warn "[$$] Q4M hasn't support to send result." if defined $result;
            $self->dbh->select_one('SELECT queue_end()');
        },
        on_abort => sub {
            my $e = shift;
            $self->dbh->select_one('SELECT queue_abort()');
        },
    );
}

sub dequeue_abort {
    my $self = shift;

    my $sth = $DBI::lasth;
    if ($sth && $sth->{Database}{private_in_queue_wait}) {
        die "[$$] RECEIVED TERM SIGNAL into queue_wait()";
    }
}

1;
__END__
