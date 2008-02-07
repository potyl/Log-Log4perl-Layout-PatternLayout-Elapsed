use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME   => 'Log::Log4perl::Layout::PatternLayout::Elapsed',
	AUTHOR => 'Emmanuel Rodriguez <emmanuel.rodriguez@gmail.com>',

	VERSION_FROM  => 'lib/Log/Log4perl/Layout/PatternLayout/Elapsed.pm',
	ABSTRACT_FROM => 'lib/Log/Log4perl/Layout/PatternLayout/Elapsed.pm',

	PREREQ_PM => {
		Log::Log4perl::Layout::PatternLayout => 0,
		Test::More => 0,
	},
);
