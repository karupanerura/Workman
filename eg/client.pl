use strict;
use warnings;
use utf8;

use Workman::Client;
use Workman::Queue::Gearman;
use Try::Tiny;
use Data::Dumper;

my $queue  = Workman::Queue::Gearman->new(job_servers => ['127.0.0.1:7003']);
my $client = Workman::Client->new(queue => $queue);

my $request = $client->enqueue(Echo => { message => 'hello!!' });
try {
    my $result = $request->wait;
    warn Dumper $result;
}
catch {
    warn "e: $_";
};
