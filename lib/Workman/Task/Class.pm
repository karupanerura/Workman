package Workman::Task::Class;
use strict;
use warnings;
use utf8;

use parent qw/Workman::Task/;

sub new {
    my $class = shift;
    return $class->SUPER::new($class);
}

sub work_job { die 'this is abstract method.' }

1;
