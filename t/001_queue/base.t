use strict;
use warnings;
use Test::More tests => 5;

use Workman::Queue;

my $queue = Workman::Queue->new();
is $queue->can_wait_job(), 1, 'default is 1';

my ($line, $file);
eval { $queue->register_tasks(); }; ($line, $file) = (__LINE__, __FILE__);
is $@, "this is abstract method. at $file line $line.\n", 'abstruct method';

eval { $queue->enqueue();        }; ($line, $file) = (__LINE__, __FILE__);
is $@, "this is abstract method. at $file line $line.\n",  'abstruct method';

eval { $queue->dequeue();        }; ($line, $file) = (__LINE__, __FILE__);
is $@, "this is abstract method. at $file line $line.\n",  'abstruct method';

eval { $queue->dequeue_abort();  }; ($line, $file) = (__LINE__, __FILE__);
is $@, "this is abstract method. at $file line $line.\n",  'abstruct method';
