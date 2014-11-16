use strict;
use warnings;
use Test::More tests => 4;

use Workman::Client;
use Workman::Queue::Mock;

my $token    = bless {};
our $on_wait = sub { $token };

my $queue  = Workman::Queue::Mock->new(enqueue_count => 0, on_wait => sub { $on_wait->() });
my $client = Workman::Client->new(queue => $queue);
isa_ok $client, 'Workman::Client';
is $queue->{enqueue_count}, 0, 'should not be enqueued yet.';

my $res = $client->enqueue_with_wait(Foo => { foo => 1, bar => 2 });
is $res, $token, 'should get token';
is $queue->{enqueue_count}, 1, 'should be enqueued once.';
