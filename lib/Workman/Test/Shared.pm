package Workman::Test::Shared;
use strict;
use warnings;
use utf8;

use JSON::XS;
use File::Temp qw/tempfile/;

sub new {
    my ($class, $initial_data) = @_;

    my ($fh, $file) = tempfile(EXLOCK => 0);
    my $json = JSON::XS->new->utf8->allow_nonref;
    my $self = bless {
        file => $file,
        json => $json,
        ppid => $$,
    } => $class;

    my $body = $json->encode($initial_data);
    syswrite $fh, $body;
    seek $fh, 0, 0;
    close $fh;

    return $self;
}

sub get_lock {
    my $self = shift;
    return Workman::Test::Shared::Lock->new($self);
}

sub txn {
    my ($self, $code) = @_;
    my $lock = $self->get_lock;

    my $fh = $lock->fh;
    my $json = do { local $/; <$fh> };
    my $data = $self->{json}->decode($json);
    $data = $code->($data);

    $json = $self->{json}->encode($data);
    seek $fh, 0, 0;
    truncate $fh, 0;
    syswrite $fh, $json;

    return;
}

sub DESTROY {
    my $self = shift;
    unlink $self->{file} if $$ == $self->{ppid};
}

package ## hide from PAUSE
    Workman::Test::Shared::Lock;
use strict;
use warnings;
use utf8;
use Fcntl qw/:flock/;

sub new {
    my ($class, $shared) = @_;
    open my $fh, '+<:raw', $shared->{file} or die "failed to open temporary file: $shared->{file}: $!";
    flock $fh, LOCK_EX;
    return bless { fh => $fh } => $class;
}

sub fh { shift->{fh} }

sub DESTROY {
    my $self = shift;
    flock $self->{fh}, LOCK_UN;
    close $self->{fh};
}

1;
__END__
