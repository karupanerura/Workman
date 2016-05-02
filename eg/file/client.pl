use strict;
use warnings;
use utf8;

use Workman::Client;
use Workman::Queue::File;
use Try::Tiny;
use Data::Dumper;

my $file = shift @ARGV or die "Usage: $0 [queue-file]";
warn "[Workman::Queue::File] file: $file";

my $queue  = Workman::Queue::File->new(file => $file);
my $client = Workman::Client->new(queue => $queue);

$client->enqueue_background(Echo => { msg => 'hello' }) for 1..10000;
