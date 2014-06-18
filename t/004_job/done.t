use strict;
use warnings;
use Test::More tests => 4;

use Workman::Job;

my ($done, $abort) = (0, 0);
my $job = Workman::Job->new(
    name => 'Foo',
    args => { this => { is => 'args' } },
    on_done  => sub { $done++  },
    on_abort => sub { $abort++ },
);
is $done,  0, 'should not done yet.';
is $abort, 0, 'should not abort yet.';

$job->done;
is $done,  1, 'should done.';
is $abort, 0, 'should not abort.';
