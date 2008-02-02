#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN {
	use_ok('Log::Log4perl::Layout::TimedPatternLayout');
}

use Log::Log4perl qw(:easy);
use Log::Log4perl::Appender::TestBuffer;


exit main();

sub main {

	init_logger();
	
	# Start some logging
	INFO "Start";

	sleep 1;
	DEBUG "Pause: 1 sec";
	
	sleep 2;
	INFO  "Pause: 2 secs";
	
	sleep 1;
	DEBUG "Pause: 1 sec";
	
	WARN "End";

	# Get the contents of the buffers
	my $buffer_a = Log::Log4perl::Appender::TestBuffer->by_name('A')->buffer();
	my $buffer_b = Log::Log4perl::Appender::TestBuffer->by_name('B')->buffer();
	
	# Get the elapse time so far
	my @a = ($buffer_a =~ / (\d+)ms /g);
	my @b = ($buffer_b =~ / (\d+)ms /g);
	
	diag("A:\n$buffer_a\n");
	diag("B:\n$buffer_b\n");
	
	is(scalar(@a), 5, "Appender A has 5 logging events");
	is(scalar(@b), 3, "Appender B has 3 logging events");

	is($a[0], $b[0], "Expecting to start at the same time");
	
	is($a[0] + $a[1] + $a[2], $b[0] + $b[1], "A1 + A2 + A3 == B1 + B2");
	is($a[3] + $a[4], $b[2], "A4 + A5 == B3");

	return 0;
}

sub init_logger {

	my $conf = <<'__END__';
log4perl.rootLogger = ALL, A, B

log4perl.appender.A = Log::Log4perl::Appender::TestBuffer
log4perl.appender.A.layout = org.apache.log4j.PatternLayout
log4perl.appender.A.layout.ConversionPattern = A %Rms %m%n
log4perl.appender.A.Threshold = ALL

log4perl.appender.B = Log::Log4perl::Appender::TestBuffer
log4perl.appender.B.layout = org.apache.log4j.PatternLayout
log4perl.appender.B.layout.ConversionPattern = B %Rms %m%n
log4perl.appender.B.Threshold = INFO
__END__

	Log::Log4perl->init(\$conf);
}
