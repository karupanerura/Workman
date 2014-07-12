use strict;
use warnings;
use Test::More;

use Workman::Test::Queue;
use Workman::Queue::File;
use File::Temp qw/tempfile/;

my (undef, $file) = tempfile(OPEN => 0);
my $queue = Workman::Queue::File->new(file => $file);
my $test  = Workman::Test::Queue->new($queue);

$test->run;

unlink $file;
done_testing;
