# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..12\n"; }
END {print "not ok 1\n" unless $loaded;}
use Log::ErrLogger qw{log_error};
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $cnt = 1;
my $logger;

#### Test Log::ErrLogger        ####

use IO::Handle;

if (!pipe(*IN, *OUT)) {
  foreach(0..3) {
	printf "not ok %d\n", ++$cnt;
  }
} else {
  printf "ok %d\n", ++$cnt;
  if (!($logger = new Log::ErrLogger( SENSITIVITY => Log::ErrLogger::ERROR ))) {
	foreach(0..2) {
	  printf "not ok %d\n", ++$cnt;
	}
  } else {
	printf "ok %d\n", ++$cnt;
	my $handle = new IO::Handle;
	$handle->fdopen(fileno(OUT), "w");
	$logger->set_file_handle($handle);

	log_error( Log::ErrLogger::ERROR,   "X");
	log_error( Log::ErrLogger::WARNING, "Y");

	$logger->close;
	close(OUT);

	my @in = <IN>;
	close(IN);

	printf "%sok %d\n", (@in==1)?"":"not ",++$cnt;
	printf "%sok %d\n", ($in[0] =~ / X$/)?"":"not ",++$cnt;
  }
}

#### Test Log::ErrLogger::File  ####

if (!($logger = new Log::ErrLogger::File( SENSITIVITY => Log::ErrLogger::WARNING,
										  FILE        => "/tmp/$$.tmp" ))) {
  foreach(0..2) {
	printf "not ok %d\n", ++$cnt;
  }
} else {
  printf "ok %d\n", ++$cnt;
  log_error( Log::ErrLogger::INFORMATIONAL, "X");
  log_error( Log::ErrLogger::ERROR,         "Y");
  $logger->close;

  if (!open(IN, "/tmp/$$.tmp")) {
	foreach(0..1) {
	  printf "not ok %d\n", ++$cnt;
	}
  } else {
	my @in = <IN>;
	close(IN);

	printf "%sok %d\n", (@in==1)?"":"not ",++$cnt;
	printf "%sok %d\n", ($in[0] =~ / Y$/)?"":"not ",++$cnt;
  }
}

#### Test Log::ErrLogger::Mail  ####
#### Test Log::ErrLogger::Sub   ####

my $x    = 0;
if (!($logger = new Log::ErrLogger::Sub( SENSITIVITY => Log::ErrLogger::WARNING,
										 SUB         => sub { $x++; } ))) {
  foreach(0..2) {
	printf "not ok %d\n", ++$cnt;
  }
} else {
  printf "ok %d\n", ++$cnt;
  log_error( Log::ErrLogger::DEBUGGING, "Test" );
  printf "%sok %d\n", ($x==0)?"":"not ", ++$cnt;
  log_error( Log::ErrLogger::ERROR, "Test" );
  printf "%sok %d\n", ($x==1)?"":"not ", ++$cnt;
}

#### Test Log::ErrLogger::Tie   ####

Log::ErrLogger::tie(Log::ErrLogger::ERROR)->close;

$x=0;
print STDERR "X";
printf "%sok %d\n", ($x==1)?"":"not ", ++$cnt;


