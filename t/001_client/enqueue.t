use strict;
use warnings;
use Test::More tests => 4;

use Workman::Client;
use Workman::Queue::Mock;

my $queue  = Workman::Queue::Mock->new(enqueue_count => 0);
my $client = Workman::Client->new(queue => $queue);
isa_ok $client, 'Workman::Client';
is $queue->{enqueue_count}, 0, 'should not be enqueued yet.';

my $job = $client->enqueue(Foo => { foo => 1, bar => 2 });
isa_ok $job, 'Workman::Request';
is $queue->{enqueue_count}, 1, 'should be enqueued once.';

