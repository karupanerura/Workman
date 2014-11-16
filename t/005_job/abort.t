use strict;
use warnings;
use Test::More tests => 6;

use Workman::Job;

my ($done, $fail, $abort) = (0, 0, 0);
my $job = Workman::Job->new(
    name => 'Foo',
    args => { this => { is => 'args' } },
    on_done  => sub { $done++  },
    on_fail  => sub { $fail++  },
    on_abort => sub { $abort++ },
);
is $done,  0, 'should not done yet.';
is $fail,  0, 'should not fail yet.';
is $abort, 0, 'should not abort yet.';

$job->abort;

is $done,  0, 'should not done.';
is $fail,  0, 'should not fail.';
is $abort, 1, 'should abort once.';
