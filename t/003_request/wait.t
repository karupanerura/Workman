use strict;
use warnings;
use Test::More tests => 5;

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
is $wait,       0, 'should not run wait task yet.';
is $background, 0, 'should not run background task yet.';

is_deeply $client->enqueue(Foo => { foo => 1, bar => 2 })->wait, {
    msg => 'success'
}, 'can get result';
is $wait,       1, 'run wait task';
is $background, 0, 'not run background task';
