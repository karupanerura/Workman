use strict;
use warnings;
use feature qw/say/;

use Workman::Client;
use Workman::Queue::Gearman;

warn "[Workman::Queue::Gearman]";

my $queue  = Workman::Queue::Gearman->new(job_servers => [qw/127.0.0.1:7003/]);
my $client = Workman::Client->new(queue => $queue);

$client->enqueue_background(Echo => { msg => 'hello' }) for 1..10000;

my $task = $client->enqueue(Echo => { msg => 'hello' });
say "Wait the task...";
say "Recieved: ", $task->wait;
