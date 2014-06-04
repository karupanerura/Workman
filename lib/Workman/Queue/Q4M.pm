package Workman::Queue::Q4M;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Queue/;

sub enable_reply { 0 }
sub reply_result {} # not supported
sub fetch_result {} # not supported

sub enqueue  { die "TODO" }
sub dequeue  { die "TODO" }
sub finalize { die "TODO" }

1;
__END__
