#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
	use_ok('Log::Log4perl::Layout::TimedPatternLayout');
}

use Log::Log4perl qw(:easy);
use Log::Log4perl::Appender::TestBuffer;


exit main();


sub main {

	init_logger();
	
	# Count the number of warnings issued by log4perl.
	# Here we are testing that the modifications to the layout don't affect the
	# PatternLayout. PatternLayout should complaing about %R.
	my $warns = 0;
	local $SIG{__WARN__} = sub {
		my ($message) = @_;
		if ($message =~ /^Invalid conversion in sprintf: "%R"/) {
			++$warns;
			return;
		}
		warn @_;
	};


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
	
	diag("Buffers:");
	diag($buffer_a);
	diag($buffer_b);
	
	is(scalar(@a), 5, "Appender A has 5 logging events");
	is(scalar(@b), 3, "Appender B has 3 logging events");

	compare_times($a[0], $b[0], "Expecting to start at the same time");
	
	compare_times($a[0] + $a[1] + $a[2], $b[0] + $b[1], "A1 + A2 + A3 == B1 + B2");
	compare_times($a[3] + $a[4], $b[2], "A4 + A5 == B3");
	
	is($warns, 3, "Appender C issued warnings");

	return 0;
}


#
# Compares the times, if the times are in milliseconds than the function will
# accept a difference of a few milliseconds.
#
sub compare_times {
	my ($got, $expected, $message) = @_;

	# We can't just compare the times for equality because it could happen that
	# the two logging statements are not perform at the same millisecond. Instead
	# compute the difference and accept a threshold
	my $diff = $got - $expected;
	$diff = -$diff if $diff < 0;

	my $threshold = 10;
	diag("Comparing $got <> $expected (diff $diff < $threshold)");
	
	# There's no way that this test will wait more than 900 seconds, so if the
	# value is greater than 900 the time is in milliseconds.
	if ($got > 900) {
		
		# Accept a small difference since we are computing in milliseconds
		if ($diff < $threshold) {
			# Fine, the difference is not too big, the test passed
			pass($message);
			return;
		}
		
		# This is bad the test failed, let's contiune. The function will compare the
		# values. Since they differ the test will fail, but at least it will report
		# which test failed and the values compared
	}

	is($got, $expected, $message);	
}


#
# Initialize the logging system
#
sub init_logger {

	my $conf = <<'__END__';
log4perl.rootLogger = ALL, A, B, C

log4perl.appender.A = Log::Log4perl::Appender::TestBuffer
log4perl.appender.A.layout = Log::Log4perl::Layout::TimedPatternLayout
log4perl.appender.A.layout.ConversionPattern = A %Rms %m%n
log4perl.appender.A.Threshold = ALL

log4perl.appender.B = Log::Log4perl::Appender::TestBuffer
log4perl.appender.B.layout = Log::Log4perl::Layout::TimedPatternLayout
log4perl.appender.B.layout.ConversionPattern = B %Rms %m%n
log4perl.appender.B.Threshold = INFO

log4perl.appender.C = Log::Log4perl::Appender::TestBuffer
log4perl.appender.C.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.C.layout.ConversionPattern = C %Rms %m%n
log4perl.appender.C.Threshold = INFO
__END__

	Log::Log4perl->init(\$conf);
}
