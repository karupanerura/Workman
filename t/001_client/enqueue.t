use strict;
use warnings;
use Test::More tests => 3;

use Workman::Client;
use Workman::Queue::Mock;

my $queue  = Workman::Queue::Mock->new;
my $client = Workman::Client->new(queue => $queue);
isa_ok $client, 'Workman::Client';

my $job = $client->enqueue(Foo => { foo => 1, bar => 2 });
isa_ok $job, 'Workman::Request';
is $queue->{enqueue_count}, 1, 'enqueue once';

