##################################################
package Log::Log4perl::Layout::TimedPatternLayout;
##################################################

use 5.006;
use strict;
use warnings;
use Carp;

use base qw(Log::Log4perl::Layout::PatternLayout);

my $CSPECS = 'R' . $Log::Log4perl::Layout::PatternLayout::CSPECS;

##################################################
sub new {
##################################################
    my $type = shift;
		
		local $Log::Log4perl::Layout::PatternLayout::CSPECS = $CSPECS;
		my $self = $type->SUPER::new(@_);
		$self->{CSPECS} = $CSPECS;
		$self->{last_time} = undef;

    return $self;
}


##################################################
sub render {
##################################################
    my($self, $message, $category, $priority, $caller_level) = @_;

    $caller_level = 0 unless defined  $caller_level;

    my %info    = ();

    $info{m}    = $message;
        # See 'define'
    chomp $info{m} if $self->{message_chompable};

    my @results = ();

    if($self->{info_needed}->{L} or
       $self->{info_needed}->{F} or
       $self->{info_needed}->{C} or
       $self->{info_needed}->{l} or
       $self->{info_needed}->{M} or
       0
      ) {
        my ($package, $filename, $line, 
            $subroutine, $hasargs,
            $wantarray, $evaltext, $is_require, 
            $hints, $bitmask) = caller($caller_level);

        # If caller() choked because of a whacko caller level,
        # correct undefined values to '[undef]' in order to prevent 
        # warning messages when interpolating later
        unless(defined $bitmask) {
            for($package, 
                $filename, $line,
                $subroutine, $hasargs,
                $wantarray, $evaltext, $is_require,
                $hints, $bitmask) {
                $_ = '[undef]' unless defined $_;
            }
        }

        $info{L} = $line;
        $info{F} = $filename;
        $info{C} = $package;

        if($self->{info_needed}->{M} or
           $self->{info_needed}->{l} or
           0) {
            # To obtain the name of the subroutine which triggered the 
            # logger, we need to go one additional level up.
            my $levels_up = 1; 
            {
                $subroutine = (caller($caller_level+$levels_up))[3];
                    # If we're inside an eval, go up one level further.
                if(defined $subroutine and
                   $subroutine eq "(eval)") {
                    $levels_up++;
                    redo;
                }
            }
            $subroutine = "main::" unless $subroutine;
            $info{M} = $subroutine;
            $info{l} = "$subroutine $filename ($line)";
        }
    }

    $info{X} = "[No curlies defined]";
    $info{x} = Log::Log4perl::NDC->get() if $self->{info_needed}->{x};
    $info{c} = $category;
    $info{d} = 1; # Dummy value, corrected later
    $info{n} = "\n";
    $info{p} = $priority;
    $info{P} = $$;
    $info{H} = $Log::Log4perl::Layout::PatternLayout::HOSTNAME;

    if($self->{info_needed}->{r} || $self->{info_needed}->{R}) {
        if($Log::Log4perl::Layout::PatternLayout::TIME_HIRES_AVAILABLE) {
            $info{r} = 
                int((Time::HiRes::tv_interval ( $Log::Log4perl::Layout::PatternLayout::PROGRAM_START_TIME ))*1000);
        } else {
            if(! $Log::Log4perl::Layout::PatternLayout::TIME_HIRES_AVAILABLE_WARNED) {
                $Log::Log4perl::Layout::PatternLayout::TIME_HIRES_AVAILABLE_WARNED++;
                # warn "Requested %r pattern without installed Time::HiRes\n";
            }
            $info{r} = time() - $Log::Log4perl::Layout::PatternLayout::PROGRAM_START_TIME;
        }
    }
    if($self->{info_needed}->{R}) {
        my $current_time = $info{r};
        my $last_time = $self->{last_time} || $current_time;
        $info{R} = $current_time - $last_time;
        $self->{last_time} = $current_time;
    }

        # Stack trace wanted?
    if($self->{info_needed}->{T}) {
        my $mess = Carp::longmess(); 
        chomp($mess);
        $mess =~ s/(?:\A\s*at.*\n|^\s*Log::Log4perl.*\n|^\s*)//mg;
        $mess =~ s/\n/, /g;
        $info{T} = $mess;
    }

        # As long as they're not implemented yet ..
    $info{t} = "N/A";

    foreach my $cspec (keys %{$self->{USER_DEFINED_CSPECS}}){
        next unless $self->{info_needed}->{$cspec};
        $info{$cspec} = $self->{USER_DEFINED_CSPECS}->{$cspec}->($self, 
                              $message, $category, $priority, $caller_level+1);
    }

        # Iterate over all info fields on the stack
    for my $e (@{$self->{stack}}) {
        my($op, $curlies) = @$e;
        if(exists $info{$op}) {
            my $result = $info{$op};
            if($curlies) {
                $result = $self->curly_action($op, $curlies, $info{$op});
            } else {
                # just for %d
                if($op eq 'd') {
                    $result = $info{$op}->format($self->{time_function}->());
                }
            }
            $result = "[undef]" unless defined $result;
            push @results, $result;
        } else {
            warn "Format %'$op' not implemented (yet)";
            push @results, "FORMAT-ERROR";
        }
    }

    #print STDERR "sprintf $self->{printformat}--$results[0]--\n";

    return (sprintf $self->{printformat}, @results);
}


1;

__END__

=head1 NAME

Log::Log4perl::Layout::TimedPatternLayout - Timed Pattern Layout

=head1 SYNOPSIS

From a log4perl configuration file:

	log4perl.rootLogger = ALL, DEV, FILE
	
	# Colored console with TimedPatternLayout
	log4perl.appender.DEV                          = Log::Log4perl::Appender::ScreenColoredLevels
	log4perl.appender.DEV.layout                   = Log::Log4perl::Layout::TimedPatternLayout
	log4perl.appender.DEV.layout.ConversionPattern = %5Rms %-5p %m [%M:%L]%n
	log4perl.appender.DEV.Threshold                = ALL
	
	
	# Log file with timestamps and elapsed time
	log4perl.appender.FILE          = Log::Dispatch::FileRotate
	log4perl.appender.FILE.filename = 'logs/app.log'
	log4perl.appender.FILE.Threshold                = ALL
	
	# Using both an the time elapsed since the begining and the last event
	log4perl.appender.FILE.layout                   = Log::Log4perl::Layout::TimedPatternLayout
	log4perl.appender.FILE.layout.ConversionPattern = %d{ISO8601} (%5rms) %-5p [%-12c] %C{2} %M:%L - %m [%5Rms]%n

Through Perl code (why would you do that?):

	use Log::Log4perl::Layout::TimedPatternLayout;
	
	my $layout = Log::Log4perl::Layout::TimedPatternLayout->new(
		'%5Rms %-5p %m [%M:%L]%n'
	);

=head1 DESCRIPTION

Creates a pattern layout according to L<Log::Log4perl::Layout::PatternLayout>,
which in turns is based on
L<http://jakarta.apache.org/log4j/docs/api/org/apache/log4j/PatternLayout.html>.

This pattern layout adds the format C<%R>, which is used to display the time
elapsed since the last logging event. In the case of the first logging event,
the time elapsed since the beginning of the application will be used.

The C<new()> method creates a new TimedPatternLayout, specifying its log format.
The format string supports all formats implemented by 
L<Log::Log4perl::Layout::PatternLayout>, with the addition of the new format:

    %R Number of milliseconds elapsed from last logging event to logging event

This pattern layout is able to deal with formatting strings using both C<%R> and
C<%r>. When both strings are used the timestamp is computed only once and shared
for both formats.

=head1 IMPLEMENTATION

The way module is implemented in order to ensure that each appender will track
it's own elapsed time. This way the time display is trully the time spent
between two consecutive log events for the given appender. Thus if different
threshold are applied to two appenders logging in the same application it's
normal that they both show different values for the time elapsed, since the 
previous logging message might have not been issued at the same time.

=head1 RATIONALE

When a program is taking a long time to execute the first instinct is to check
the logs and to find two consecutive log events with a high logging time 
difference. This can sometimes show where program is taking a lot of time, or
how much time a single loop iteration takes.

The problem is that the time elapsed between to logging events is not directly
available in the logs. This value needs to be computed, usually by another
program. This can be tedious as log patterns can change and might not always be
on a single line. In fact, in a single application different appenders might
even use different patterns and different thresholds.

This is why this Perl module was created. Now the time elapsed between two
consecutive log events can be automatically inserted into the log statement.

=head1 SEE ALSO

L<Log::Log4perl::Layout::PatternLayout>.

=head1 AUTHOR

Emmanuel Rodriguez, E<lt>emmanuel.rodriguez@gmail.comE<gt>.

=cut
