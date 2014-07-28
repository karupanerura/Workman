requires 'Class::Accessor::Lite';
requires 'Class::Data::Lazy';
requires 'Exception::Tiny';
requires 'File::Path', '2.00';
requires 'File::Temp';
requires 'JSON::XS';
requires 'List::MoreUtils';
requires 'List::Util';
requires 'Log::Minimal';
requires 'Module::Load';
requires 'Parallel::Prefork', '0.17';
requires 'Parallel::Scoreboard';
requires 'Plack::Loader';
requires 'Plack::Request';
requires 'Proc::Guard';
requires 'Scalar::Util';
requires 'Socket';
requires 'Sys::SigAction';
requires 'Test::Builder';
requires 'Test::SharedFork', '0.28';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'parent';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Tiny';
    requires 'Test::Builder::Module';
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
