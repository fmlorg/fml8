#!perl5

use strict;

package Log::ErrLogger;

=head1 NAME

Log::ErrLogger - Log errors and error-like events

=head1 SYNOPSIS

  use Log::ErrLogger;

  # Send e-mail for ERROR or worse
  my $mail_logger = new Log::ErrLogger::Mail(
    SENSITIVITY => Log::ErrLogger::ERROR,
    HEADERS     => { To      => "who@where.com",
					 Subject => "Errors occurred while running $0" });

  # Log INFORMATIONAL or worse to a file
  my $file_logger = new Log::ErrLogger::File(
    FILE        => "/home/who/what.err",
    SENSITIVITY => Log::ErrLogger::INFORMATIONAL );

  # Print a nice HTML error message
  my $sub_logger  = new Log::ErrLogger::Sub (
    SENSITIVITY => FATAL,
    SUB         => sub { print STDOUT "<TITLE>Oops!</TITLE><HTML><HEAD1>Please try again later.</HEAD1></HTML>\n";
						 exit(0); } );

  # Capture all output to STDERR as an UNEXPECTED error
  my $stderr_logger = Log::ErrLogger::tie( Log::ErrLogger::UNEXPECTED );

  # But don't actually print to STDERR
  $stderr_logger->close;

  # Log a warning
  log_error( WARNING, "Danger, %s!", "Will Robinson" );

=head1 DESCRIPTION

Log::ErrLogger provides a means of logging errors and error-like events (such
as warnings and unexpected situations) when printing to STDERR just will not do.

Error-like events are classified by a severity (see L<ERROR SEVERITIES> below).
Programs instantiate error logging objects which can respond differently to
events.  The objects have a sensitivity -- they will respond to any event at
least as severe as their sensitivity, and will ignore any events that are less
severe.

This module instantiates new __DIE__ and __WARN__ handlers that call
log_error( FATAL, die-message) and log_error( WARNING, warn-message), respectively.

=head1 HISTORY

$Id: ErrLogger.pm,v 1.6 1999/09/23 21:37:24 dcw Exp $

$Log: ErrLogger.pm,v $
Revision 1.6  1999/09/23 21:37:24  dcw
Incorporated Tim Ayers <tayers@bridge.com> suggestions

Revision 1.5  1999/09/13 17:59:48  dcw
Copyright

Revision 1.4  1999/09/13 16:37:17  dcw
Documentation

Revision 1.3  1999/09/01 14:28:28  dcw
Backup file, export, autoflush

Revision 1.2  1999/08/31 17:18:39  dcw
Log::ErrLogger::Sub

Revision 1.1  1999/08/30 21:28:43  dcw
Initial

=head1 AUTHOR

David C. Worenklein <dcw@gcm.com>

=head1 COPYRIGHT

Copyright 1999 Greenwich Capital Markets

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 ERROR SEVERITIES

The predefined severities are

=over 4

=item DEBUGGING

=item INFORMATIONAL

=item UNEXPECTED

=item WARNING

=item ERROR

=item FATAL

=back

They have numerical values from 1 to 6.

=cut

use vars qw{@Errors};
BEGIN {
  @Errors = qw{
			   ALL
			   DEBUGGING
			   INFORMATIONAL
			   UNEXPECTED
			   WARNING
			   ERROR
			   FATAL
			   NONE
			  };
}



#################################
# Typical object-oriented stuff #
#################################

use Exporter;

use vars qw{ @ISA @EXPORT_OK %EXPORT_TAGS $VERSION };

@ISA         = qw{ Exporter };
@EXPORT_OK   = (@Errors, "log_error", "tie", "LogError", "Tie");
%EXPORT_TAGS = (ErrorLevels => [@Errors]);
($VERSION)   = ( qw$Revision: 1.6 $ )[1];

use IO::Handle;



##############
# Prototypes #
##############

sub log_error( $$;@ );
sub tie( ;$ );
sub new( $;% );

# Prototypes don't do much for methods, but they make the code more readable.
sub sensitivity( $ );
sub set_sensitivity( $$ );
sub file_handle( $ );
sub set_file_handle( $$ );
sub log( $$$ );
sub close( $ );



###############################
# Set up the error severities #
###############################

for(my $i=0; $i<scalar(@Errors); $i++) {
  eval " use constant $Errors[$i] => $i ";
}



###########################
# Commandeer DIE and WARN #
###########################

$SIG{__DIE__}  = sub { if (defined($^S)) { Log::ErrLogger::log_error( &Log::ErrLogger::FATAL,   "%s", @_ ); } else { die  @_; } };
$SIG{__WARN__} = sub { if (defined($^S)) { Log::ErrLogger::log_error( &Log::ErrLogger::WARNING, "%s", @_ ); } else { warn @_; } };



##########################################
# Here are the logging methods specified #
##########################################

my @LogMethods;




=head1 NON-METHOD SUBROUTINES


=over 4

=item log_error( SEVERITY, FORMAT [,LIST] )

Log an error of the specified severity.  The text of the message is the output of
sprintf FORMAT, ARGS.  A carriage-return (\n) will be appended if one is not
supplied.

=cut

sub log_error( $$;@ ) {
  my ($severity, $format, @args) = @_;

  my $message = sprintf $format, @args;
  # Add \n if needed
  $message .= "\n" unless substr($message, -1) eq "\n";

  my $fatal;

  foreach my $logger (@LogMethods) {
	if ($logger->sensitivity <= $severity) {

	  # An error logger can attempt to die
	  eval { $logger->log( $severity, $message ) };
	  $fatal ||= $@;
	}
  }

  # Did we hit a dieing error logger?
  die $fatal if $fatal;
}

*LogError = \&log_error;


###############################################################################


=item my $stderr_logger = tie( [SEVERITY] );

Tie the STDERR handle to the Log::ErrLogger module, so that any output to
STDERR will call log_error( $severity, output ).

If $severity is not specified, it will default to INFORMATIONAL.

=cut

my $stderr_handler;

sub tie( ;$ ) {
  my ($severity) = @_;

  $severity = &INFORMATIONAL unless defined($severity);

  my $handler = new Log::ErrLogger SENSITIVITY => $severity;

  # Copy off what STDERR was
  open(OLD_STDERR, ">&STDERR");

  $handler->set_file_handle(*OLD_STDERR);

  $stderr_handler = tie *STDERR, ref($handler), $severity;

  return $handler;
}

*Tie = \&tie;

sub TIEHANDLE( $ ) {
  my ($class, $severity) = @_;
  return bless \$severity, $class;
}

sub PRINT( $$ ) {
  my ($self, $message) = @_;
  Log::ErrLogger::log_error( $$self, "%s", $message );
}

sub PRINTF( $$;@ ) {
  my ($self, $format, @args) = @_;
  Log::ErrLogger::log_error( $$self, $format, @args );
}


###############################################################################


=back

=head1 METHODS

=over 4

=item my $sensitivity = $logger->sensitivity;

Returns the sensitivty of an error logger object.  Objects respond to
events that are at least as severe as their sensitivity.  There are
two special sensitivities.  Objects with a sensitivity of NONE do not
respond to any events.  Objects with a sensitivity of ALL respond
to all events.

=cut

sub sensitivity( $ ) {

  my ($self) = @_;

  return $self->{SENSITIVITY};
}


###############################################################################


=item my $old_sensitivity = $logger->sensitivity( SENSITIVITY );

Sets the sensitivty of an error logger object.  Objects respond to events
that are at least as severe as their sensitivity.

Returns what the sensitivity of the object used to be.

=cut

sub set_sensitivity( $$ ) {

  my ($self, $sensitivity) = @_;

  my $old_sensitivity = $self->{SENSITIVITY};
  $self->{SENSITIVITY} = $sensitivity;

  return $old_sensitivity;
}



###############################################################################

=item my $fh = $logger->file_handle;

Returns the IO::Handle associated with the error logger object.  Not all
error loggers will have a file handle, but most will.

=cut

sub file_handle( $ ) {
  my ($self) = @_;

  return $self->{FILEHANDLE};
}


###############################################################################

=item $logger->set_file_handle( HANDLE );

Associates the error logger object with the given (opened) IO::Handle, and
closes the old file handle that used to be associated with the object (if
there was one.)

The handle is set to autoflush, since buffering is usually a bad idea on
error loggers.

=cut

sub set_file_handle( $$ ) {
  my ($self, $handle) = @_;

  if (defined($self->file_handle)) {
	$self->file_handle->close;
  }

  $self->{FILEHANDLE} = $handle;
  $self->{FILEHANDLE}->autoflush(1);
}


###############################################################################

=item $logger->close;

Decommission the error logging object.  L<log_error> will no longer invoke
this object.

Note that this does NOT close the associated file handle.  However, if the
error logging object has the only reference to the file handle, and the
program does not have any references to the error logging object, the handle
will have no references left and will be destroyed.

=cut

sub close( $ ) {
  my ($self) = @_;

  @LogMethods = grep { $_ != $self } @LogMethods;
}




###############################################################################

=item $logger->log( SEVERITY, MESSAGE );

This is the method called by L<log_error>, above.  It prints

<time>: <message>

to the associated file handle, where <time> is the output of L<localtime>,
evaluated in a scalar context.

Additionally, if the object has a TRACE attribute that is at least
as large as the error severity, this method will print a trace of where
the error occurred:

<spaces>: From <subroutine1>, at <filename1>:<line1>
<spaces>: From <subroutine2>, at <filename2>:<line2>

where <spaces> is the number of spaces needed to make all the colons line up.

=cut

sub log( $$$ ) {
  my ($self, $severity, $message) = @_;

  if (defined($self->file_handle)) {
	my $time = scalar(localtime);
	print { $self->file_handle } "$time: $message";
	if (defined($self->{TRACE}) && $self->{TRACE} >= $severity) {
	  # Show context
	  my $i=1;
	  my ($package, $filename, $line, $subroutine) = caller($i);

	  while(defined($subroutine)) {
		printf { $self->file_handle } "%s: From %s, at %s:%s\n", " "x length($time), $subroutine, $filename, $line
		  if ($filename ne __FILE__ && $subroutine !~ /^Log::ErrLogger/);
		($package, $filename, $line, $subroutine) = caller(++$i);
	  }
	}
  }
}



###############################################################################

=back

=head1 CONSTRUCTORS

The following erorr logging classes are provided by the module:

=over 4

=item my $logger = new Log::ErrLogger( [parameter-hash] );

Creates a new error logging object that uses the default L<log>
given above.  The parameters that are understood are

=over 4

=item SENSITIVITY

The sensitivity of the object.  Defaults to INFORMATIONAL or, in
the perl debugger, DEBUGGING.

=item TRACE

Events that are at least as severe as the TRACE value will have their
call stack printed.

=back

=cut

sub new( $;% ) {
  my ($class, %options) = @_;

  my $self = bless { %options }, $class;

  if (!defined( $self->sensitivity )) {
	$self->set_sensitivity( $^P ? &DEBUGGING : &INFORMATIONAL );
  }

  push(@LogMethods, $self);

  return $self;
}


###############################################################################

=item my $logger = new Log::ErrLogger::File( [parameter-hash] );

Creates an error logging object that logs events to a file.  In addition
to the parameters that the Log::ErrLogger constructor takes, it also
takes

=over 4

=item FILE

Name of the file that in which to log events.  Defaults to /tmp/<program-base-name>.<pid>.err.
See the L<set_file> method, below, for details.

=back

=cut

package Log::ErrLogger::File;

use vars qw{ @ISA $VERSION };

@ISA     = qw{ Log::ErrLogger };
$VERSION = $Log::ErrLogger::VERSION;

use IO::File;



# Prototypes don't do much for methods, but they make the code more readable.
sub new( $;% );
sub filename( $ );
sub set_file( $$ );


sub new( $;% ) {
  my ($class, %options) = @_;

  # Default file name
  $0 =~ m:([^/]+)$:;
  $options{FILE} ||= "/tmp/$1.$$.err";

  my $self = Log::ErrLogger::new( $class, %options );

  $self->set_file( $self->filename );

  return $self;
}


###############################################################################

=pod

Log::ErrLogger::File objects also provides the following methods:

=over 4

=item my $filename = $filelogger->filename();

Returns the name of the file to which events are logger.

=cut

sub filename( $ ) {
  my ($self) = @_;

  return $self->{FILE};
}


###############################################################################


=item my $old_filename = $filelogger->set_file( $new_filename [, mode [, perms]])

Opens the given file for output and sets its FILEHANDLE to that file.  An ERROR
event is generated if the file could not be opened.

Note that the file is opened by putting a ">" at the beginning and creating a
new IO::File object.  This means that if the filename given already begins with
a ">", the file will be opened for appending.

If the file already exists, it is renamed by appending ".bak" to it.  A WARNING
event is generated if the file could not be backed up.

Returns the old filename that errors used to be logged to.

=cut

sub set_file( $$ ) {
  my ($self, $file) = @_;

  my $oldfile = $self->filename;

  # Try to create a backup file
  if ( -f $file ) {
	my $backup = $file . ".bak";
	!-f $backup || unlink($backup) ||
	  Log::ErrLogger::log_error( &Log::ErrLogger::WARNING, "Could not remove old backup file %s: %s", $backup, $!);
	rename( $file, $backup) ||
	  Log::ErrLogger::log_error( &Log::ErrLogger::WARNING, "Could not create backup file %s: %s", $backup, $!);
  }

  $self->{FILE} = $file;
  $self->set_file_handle(new IO::File ">$file");

  if (defined($self->file_handle)) {
	$self->file_handle->autoflush(1);
  } else {
	Log::ErrLogger::log_error( &Log::ErrLogger::ERROR, "Could not open file %s: %s", $file, $! );
  }

  return $oldfile;
}


###############################################################################

=back

=item my $logger = new Log::ErrLogger::Mail( [parameter-hash] );

Log events by sending email to interested parties. In addition to the
parameters that the Log::ErrLogger constructor takes, it also takes

=over 4

=item HEADERS

A reference to a hash containing the headers of the e-mail, such as To and
Subject.

=back

If no sufficiently severe events occur, no email is sent.  (In other words,
you will not get a blank e-mail.)

=cut

package Log::ErrLogger::Mail;

use vars qw{ @ISA $VERSION };

@ISA     = qw{ Log::ErrLogger };
$VERSION = $Log::ErrLogger::VERSION;

use Mail::Mailer;



# Prototypes don't do much for methods, but they make the code more readable.
sub new( $;% );
sub log( $$$ );



sub new( $;% ) {
  my ($class, %options) = @_;

  return Log::ErrLogger::new( $class, %options );
}



##############################################################
# Log an error.  This is where we set up the e-mail message. #
# If this is never called, mail is never sent.               #
##############################################################

sub log( $$$ ) {
  my ($self, $severity, $message) = @_;

  if (!defined($self->file_handle)) {
	$self->set_file_handle( new Mail::Mailer 'smtp', Server => "127.0.0.1" );
	$self->file_handle->open( $self->{HEADERS} );
  }

  $self->SUPER::log($severity, $message);
}


###############################################################################

=item my $logger = new Log::ErrLogger::Sub( [parameter-hash] );

Calls a user specified subroutine every time a sufficiently severe events occurs.
In addition to the parameters that the Log::ErrLogger constructor takes, it also
takes

=over 4

=item SUB

A reference (regular or symbolic) to the subroutine to be called.  The
subroutine will receive two parameters -- the event message and the
error severity.  This parameter MUST be supplied to the constructor.

Note that, within this subroutine, STDERR is what you would want it to
be, even if the program has used tie to capture STDERR.  Thus, the
subroutine does not have to worry that output to STDERR will cause
infinite recursion.

=cut

package Log::ErrLogger::Sub;

use vars qw{ @ISA $VERSION };

@ISA     = qw{ Log::ErrLogger };
$VERSION = $Log::ErrLogger::VERSION;



# Prototypes don't do much for methods, but they make the code more readable.
sub new( $;% );
sub log( $$$ );



##########################################################################
# Create a new instance that causes errors to be logged via a subroutine #
##########################################################################

use Carp;

sub new( $;% ) {
  my ($class, %options) = @_;

  if (!exists($options{SUB})) {
	croak __PACKAGE__ . " must have a SUB specified";
  }

  return Log::ErrLogger::new( $class, %options );
}



########################################################
# Log an error by calling a user specified subroutine. #
########################################################

sub log( $$$ ) {
  my ($self, $severity, $message) = @_;

  # Put back the old STDERR, if necessary
  if ($stderr_handler) {
	local($^W)=0;  # Don't care that untie attempted
	untie *STDERR;
	open(STDERR, ">&Log::ErrLogger::OLD_STDERR");
  }

  if (ref($self->{SUB}) eq "CODE") {
	&{$self->{SUB}}($message, $severity);
  } else {
	eval "$self->{SUB}(\$message, \$severity)";
  }

  if ($stderr_handler) {
	$stderr_handler = tie *STDERR, ref($stderr_handler), $$stderr_handler;
  }
}



1;
