use strict;
use warnings;
use Test::More tests => 3;

use Workman::Job;

my $job = Workman::Job->new(
    name => 'Foo',
    args => { this => { is => 'args' } },
);
isa_ok $job, 'Workman::Job';
is $job->name, 'Foo', 'should get name.';
is_deeply $job->args, { this => { is => 'args' } }, 'should get args.';
