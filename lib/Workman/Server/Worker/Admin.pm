package Workman::Server::Worker::Admin;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Server::Worker/;

use Class::Accessor::Lite rw => [qw/harakiri/];

use Workman;
use Plack::Loader;
use Plack::Request;

sub _run {
    my $self = shift;
    my $app  = $self->_create_app;
    my %args = $self->_create_args;
    Plack::Loader->load(Standalone => %args)->run($app);
}

sub _create_args {
    my $self = shift;
    return (
        server_software => sprintf('Workman/%s', $Workman::VERSION),
        port            => $self->server->profile->admin_port, # TODO
    );
}

sub _create_app {
    my $self = shift;
    $self->{in_app} = 0;
    return sub {
        my $env = shift;
        local $self->{in_app} = 1;

        my $res = $self->_request_handler($env);
        $env->{'psgix.harakiri.commit'} = 1 if $self->harakiri;
        return $res;
    };
}

sub _request_handler {
    my ($self, $env) = @_;

    (my $action = $env->{PATH_INFO}) =~ s{/+}{_}g;
    my $method = sprintf '_action%s', $action;
    if ($self->can($method)) {
        return $self->$method($env);
    }
    else {
        return [404, [], ['not found']];
    }
}

sub _action_rpc_scoreboard {
    my ($self, $env) = @_;

    my %result;
    my $stats = $self->server->scoreboard->read_all();
    for my $pid (keys %$stats) {
        $result{$pid} = $self->json->decode($stats->{$pid} || '{}');
    }

    return $self->_res_json(\%result);
}

sub _res_json {
    my ($self, $res) = @_;
    return [
        200,
        ['Content-Type' => 'application/json'],
        [$self->json->encode($res)]
    ];
}

# override
sub shutdown :method {
    my ($self, $sig) = @_;
    ## TODO: logging

    if ($self->{in_app}) {
        $self->harakiri(1);
    }
    else {
        exit 0;
    }
}

# override
sub abort {
    my ($self, $sig) = @_;

    ## TODO: logging
    exit 1;
}

1;
__END__
