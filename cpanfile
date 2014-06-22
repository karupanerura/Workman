requires 'Class::Accessor::Lite';
requires 'Class::Data::Lazy';
requires 'Exception::Tiny';
requires 'JSON::XS';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Module::Load';
requires 'Parallel::Prefork';
requires 'Parallel::Scoreboard';
requires 'Plack::Loader';
requires 'Plack::Request';
requires 'Proc::Guard';
requires 'Scalar::Util';
requires 'Sys::SigAction';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'parent';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Tiny';
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
