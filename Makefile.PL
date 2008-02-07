use 5.00503;
use inc::Module::Install;

name 'Log-Log4perl-Layout-PatternLayout-Elapsed';
all_from 'lib/Log/Log4perl/Layout/PatternLayout/Elapsed.pm';
#license 'perl';

requires Log::Log4perl::Layout::PatternLayout => 0;

recommends Time::HiRes => 0;

# Modules used for testing and building
build_requires Test::More => 0;
build_requires Test::Pod => 0;
#build_requires Test::Distribution => 0;

build_requires Log::Log4perl::Appender::TestBuffer => 0;


WriteAll;
