# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Log-Log4perl-Layout-TimedPatternLayout.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Log::Log4perl::Layout::TimedPatternLayout;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

