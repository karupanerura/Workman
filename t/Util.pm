package t::Util;
use strict;
use warnings;
use utf8;

use parent qw/Test::Builder::Module/;
use Log::Minimal;

$Log::Minimal::PRINT = do {
    my $super = $Log::Minimal::PRINT;
    sub {
        local $SIG{__WARN__} = sub { __PACKAGE__->builder->note(@_) };
        $super->(@_);
    };
};

1;
