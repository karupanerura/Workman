use strict;
use warnings;
use Test::More;
use t::Util;

use Test::TCP qw/empty_port/;
use HTTP::Tiny;
use File::Spec;

use Workman::Server::Profile;
use Workman::Server::Worker::Admin;
use Parallel::Scoreboard;

my $port       = empty_port();
my $profile    = Workman::Server::Profile->new(admin_port => $port);
my $scoreboard = Parallel::Scoreboard->new(
    base_dir => File::Spec->catfile(
        File::Spec->tmpdir,
        "test-Workman-scoreboard-$$"
    ),
);

my $worker = Test::TCP->new(
    port => $port,
    code => sub {
        Workman::Server::Worker::Admin->new(
            profile    => $profile,
            scoreboard => $scoreboard,
        )->run
    },
);

my $ua = HTTP::Tiny->new;
subtest 'request rpc/scoreboard' => sub {
    my $res = $ua->get("http://localhost:$port/rpc/scoreboard");
    is $res->{status}, 200, 'should be success';
    is $res->{content}, '{}', 'should return empty json object.';
};

note 'update scoreboard.';
$scoreboard->update('{"foo":"bar"}');

subtest 'request rpc/scoreboard' => sub {
    my $res = $ua->get("http://localhost:$port/rpc/scoreboard");
    is $res->{status}, 200, 'should be success';
    is $res->{content}, qq!{"$$":{"foo":"bar"}}!, 'should return scoreboard ad json.';
};

$worker->stop;
done_testing;
