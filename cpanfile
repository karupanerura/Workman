requires 'Class::Accessor::Lite';
requires 'Exception::Tiny';
requires 'Parallel::Prefork';
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
