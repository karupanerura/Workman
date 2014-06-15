requires 'AnyEvent';
requires 'AnyEvent::Gearman::Client';
requires 'AnyEvent::Gearman::Worker';
requires 'Class::Accessor::Lite';
requires 'DBIx::Sunny';
requires 'Exception::Tiny';
requires 'JSON', '2';
requires 'Parallel::Prefork';
requires 'Qudo';
requires 'SQL::Maker';
requires 'Sys::SigAction';
requires 'Time::HiRes';
requires 'Try::Tiny';
requires 'parent';

on configure => sub {
    requires 'CPAN::Meta';
    requires 'CPAN::Meta::Prereqs';
    requires 'Module::Build';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More', '0.98';
};
