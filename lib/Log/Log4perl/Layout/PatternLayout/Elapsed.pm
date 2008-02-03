package Log::Log4perl::Layout::PatternLayout::Elapsed;

=head1 NAME

Log::Log4perl::Layout::PatternLayout::Elapsed - Timed Pattern Layout

=head1 SYNOPSIS

From a log4perl configuration file:

	log4perl.rootLogger = ALL, DEV, FILE
	
	# Colored console with PatternLayout::Elapsed
	log4perl.appender.DEV                          = Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.DEV.layout                   = Log::Log4perl::Layout::PatternLayout::Elapsed
	log4perl.appender.DEV.layout.ConversionPattern = %5Rms %-5p %m [%M:%L]%n
	log4perl.appender.DEV.Threshold                = ALL
	
	
	# Log file with timestamps and elapsed time
	log4perl.appender.FILE           = Log::Dispatch::FileRotate
	log4perl.appender.FILE.filename  = 'logs/app.log'
	log4perl.appender.FILE.Threshold = ALL
	
	# Using both an the time elapsed since the begining and the last event
	log4perl.appender.FILE.layout                   = Log::Log4perl::Layout::PatternLayout::Elapsed
	log4perl.appender.FILE.layout.ConversionPattern = %d{ISO8601} (%5rms) %-5p [%-12c] %C{2} %M:%L - %m [%5Rms]%n

Through Perl code (why would you do that?):

	use Log::Log4perl::Layout::PatternLayout::Elapsed;
	
	my $layout = Log::Log4perl::Layout::PatternLayout::Elapsed->new(
		'%5Rms %-5p %m [%M:%L]%n'
	);

=head1 DESCRIPTION

Creates a pattern layout according to L<Log::Log4perl::Layout::PatternLayout>,
which in turns is based on
L<http://jakarta.apache.org/log4j/docs/api/org/apache/log4j/PatternLayout.html>.

This layout adds the placeholder C<%R>, which is used to display the time
elapsed since the last logging event. In the case of the first logging event,
the time elapsed since the beginning of the application will be used.

The C<new()> method creates a new PatternLayout::Elapsed, specifying its log
format. The format string supports all placeholders implemented by 
L<Log::Log4perl::Layout::PatternLayout>, with the addition of the new
placeholder:

    %R Number of milliseconds elapsed since the last logging event

=head1 IMPLEMENTATION

This module is implemented in order to ensure that each appender will track it's
own elapsed time. This way the time displayed is truly the time spent between
two consecutive log events for each appender. Thus if different threshold are
applied to two appenders logging in the same application it's normal if they
both show different values for the time elapsed for a same log statement. This
is because the previous logging message might have not been issued at the same
time due to the different thresholds.

Therefore the following Perl code:

	use Time::HiRes qw(sleep);
	INFO "Start";
	
	sleep 0.1;
	DEBUG "Pause: 0.1 sec";
	
	sleep 1.5;
	INFO  "Pause: 1.5 secs";
	
	sleep 0.5;
	DEBUG "Pause: 0.5 sec";
	
	WARN "End";

When executed with the following Log4perl configuration:

	log4perl.rootLogger = ALL, A, B
	
	log4perl.appender.A = Log::Log4perl::Appender::Screen
	log4perl.appender.A.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
	log4perl.appender.A.layout.ConversionPattern = %5rms %-5p   A %5Rms %m%n
	log4perl.appender.A.Threshold = ALL

	log4perl.appender.B = Log::Log4perl::Appender::Screen
	log4perl.appender.B.layout = Log::Log4perl::Layout::PatternLayout::Elapsed
	log4perl.appender.B.layout.ConversionPattern = B %5Rms %m%n
	log4perl.appender.B.Threshold = INFO

Will produce the following results (output merged side by side manually):

	  %r    %p   Logger   %R        %m            Logger   %R       %m
	  44ms INFO    A       0ms  Start           |   B      0ms  Start
	 144ms DEBUG   A     100ms  Pause: 0.1 sec  |
	1644ms INFO    A    1500ms  Pause: 1.5 secs |   B   1600ms  Pause: 1.5 secs
	2144ms DEBUG   A     500ms  Pause: 0.5 sec  |
	2145ms WARN    A       1ms  End             |   B    501ms  End

=head1 RATIONALE

When a program is taking a long time to execute the first instinct is to check
the logs and to find which logging statements where issued after the hotspot.

The problem is that the time elapsed between to logging events is not directly
available in the logs. This value needs to be computed, usually by another
program by subtracting the times logged between to consecutive logging events.
This can be tedious as log patterns can change and might not always be on a
single line. In fact, in a single application different appenders might even
use different patterns and different thresholds.

That's why this Perl module was created. Now the time elapsed between two
consecutive log events can be automatically inserted into the log statement.
This is now performed by Log4perl and doesn't require an external script in
order to compute the values.

=head1 METHODS

This module defines the following methods:

=cut

use 5.006;

use strict;
use warnings;

use Carp;

use base qw(Log::Log4perl::Layout::PatternLayout);

our $VERSION = '0.01';

=head2 new

This is the class constructor it ensures that the placeholder C<%R> is handled
by Log4perl.

=cut

sub new {
	my $type = shift;
	
	#
	# The placeholder %R must be added through the options. Using add_layout_cspec
	# doesn't work. So we have to make sure that options are available in order to
	# add the definition of the placeholder.
	#

	# Get the options passed, if there are no options provide our own
	my $options;
	if (ref $_[0] eq 'HASH') {
		$options = $_[0];
	}
	else {
		$options = {};
		unshift @_, $options;
	}

	# Provide our implementation of %R
	$options->{cspec}{R}{value} = \&compute_elapsed_time;

	return $type->SUPER::new(@_);
}


=head2 compute_elapsed_time

Compute the value for the placeholder C<%R>.

=cut

sub compute_elapsed_time {
	my ($self, $message, $category, $priority, $caller_level) = @_;

	# Get the current time
	my $current_time;
	if ($Log::Log4perl::Layout::PatternLayout::TIME_HIRES_AVAILABLE) {
		$current_time = int(Time::HiRes::gettimeofday() * 1000);
	}
	else {
		$current_time = time();
	}

	# Get the time of the last event
	my $last_time = $self->{last_time} || $current_time;

	# Remember the current time as the last time
	$self->{last_time} = $current_time;

	# Compute the elapsed time
	my $elapsed = $current_time - $last_time;
	return $elapsed;
}

1;


=head1 SEE ALSO

L<Log::Log4perl::Layout::PatternLayout>.

=head1 AUTHOR

Emmanuel Rodriguez, E<lt>emmanuel.rodriguez@gmail.comE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Emmanuel Rodriguez

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut