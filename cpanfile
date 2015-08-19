requires 'Class::Accessor::Lite';
requires 'Class::Data::Lazy';
requires 'Exception::Tiny';
requires 'File::Path', '2.00';
requires 'File::Temp';
requires 'JSON::XS';
requires 'List::Util', '1.35';
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
requires 'Test::Differences';
requires 'Test::SharedFork', '0.28';
requires 'Test::SharedObject';
requires 'Time::HiRes';
requires 'Try::Tiny', '0.04';
requires 'parent';
requires 'perl', 'v5.8.1';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'HTTP::Tiny';
    requires 'Test::Builder::Module';
    requires 'Test::More', '0.98';
    requires 'Test::TCP';
};
