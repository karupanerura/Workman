package Workman::Queue;
use strict;
use warnings;
use utf8;

sub enable_reply { 1 }
sub reply_result { die "this is abstruct method." }
sub fetch_result { die "this is abstruct method." }

sub enqueue  { die "this is abstruct method." }
sub dequeue  { die "this is abstruct method." }
sub finalize { die "this is abstruct method." }
1;
__END__
