use strict;
use warnings;
use Test::More;

use Workman::Test::Queue;
use Workman::Queue::Mock;

my $queue = Workman::Queue::Mock->new(enqueue_count => 0);
my $test  = Workman::Test::Queue->new($queue);

$test->run;
