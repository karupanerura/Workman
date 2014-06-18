use strict;
use warnings;
use Test::More tests => 2;

use Workman::Client;
use Workman::Queue::Mock;

my ($wait, $background) = (0, 0);
my $queue  = Workman::Queue::Mock->new(
    on_wait => sub {
        ++$wait;
        return +{
            msg => 'success'
        };
    },
    on_background => sub {
        ++$background;
    }
);
my $client = Workman::Client->new(queue => $queue);
$client->enqueue(Foo => { foo => 1, bar => 2 });
is $wait,       0, 'not run wait task';
is $background, 1, 'run background task';
