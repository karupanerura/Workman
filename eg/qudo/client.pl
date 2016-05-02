use strict;
use warnings;
use utf8;

use Qudo;
use Workman::Client;
use Workman::Queue::Qudo;
use Try::Tiny;
use Data::Dumper;

my $file = shift @ARGV or die "Usage: $0 [sqlite-file]";
warn "[Workman::Queue::Qudo] file: $file";

my $qudo = Qudo->new(
    databases => [
        {
            dsn      => "dbi:SQLite:dbname=$file",
            username => '',
            password => '',
        }
    ],
    default_hooks => [qw/Qudo::Hook::Serialize::JSON/],
);
my $queue  = Workman::Queue::Qudo->new(qudo => $qudo);
my $client = Workman::Client->new(queue => $queue);

$client->enqueue_background(Echo => { msg => 'hello' }) for 1..10000;
