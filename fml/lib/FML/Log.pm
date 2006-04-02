#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#
# $FML: Log.pm,v 1.32 2005/08/23 08:28:20 fukachan Exp $
#

package FML::Log;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(Log LogWarn LogError);

use strict;
use Carp;
use FML::Config;
use FML::Credential;

=head1 NAME

FML::Log - logging functions.

=head1 SYNOPSIS

To import Log(),

   use FML::Log qw(Log LogWarn LogError);
   Log( $log_message );

or specify arguments in the hash reference

   use FML::Log qw(Log LogWarn LogError);
   Log( $log_message , {
       log_file => $log_file,
       priority => $priority,
       facility => $facility,
       level    => $level,
   });

=head1 DESCRIPTION

FML::Log contains several interfaces to write log messages, for
example, log files, syslog() (not yet implemented).

=head2 Log( $message [, $args])

The required argument is the message to log.
You can specify C<log_file>, C<facility> and C<level> as an optional.

    $args = {
       log_file => $log_file,
       priority => $priority,
       facility => $facility,
       level    => $level,
   };

This routine depends on C<FML::Config> and C<FML::Credential>.
$config->{ log_format_type } defines the format sytle.
C<sender> to log is taken from C<FML::Credential> object.

Key C<log_format_type> changes the log format.
By default, our log format is same as fml 4.0 format.

=head2 LogWarn( $message [, $args])

same as Log("warn: $message", $args);

=head2 LogError( $message [, $args])

same as Log("error: $message", $args);

=cut


# Descriptions: write message $msg to logfile.
#    Arguments: STR($mesg) HASH_REF($args)
# Side Effects: update logfile
# Return Value: none
sub Log
{
    my ($mesg, $args) = @_;
    my $config   = new FML::Config;
    my $log_file = '';
    my $priority = '';
    my $facility = '';
    my $level    = '';
    my $rdate    = '';

    # clean up
    $mesg =~ s/[\s\r\n]*$//;

    # simple check: null $mesg string is invalid.
    return undef unless defined $mesg;
    return undef unless $mesg;

    # XXX allow "log_type = file, syslog", o.k.?
    if ($config->{ log_type } =~ /syslog/) {
	my $ident    = $config->{ log_syslog_ident }    || 'fml8';
	my $logopt   = $config->{ log_syslog_options }  || 'pid';
	my $facility = $config->{ log_syslog_facility } || 'local0';
	my $priority = $config->{ log_syslog_priority } || 'info';
	my $hosts    = $config->get_as_array_ref('log_syslog_servers') || [];

	use Sys::Syslog;
	for my $host (@$hosts) {
	    if ($host) { $Sys::Syslog::host = $host;}
	    openlog($ident, $logopt, $facility);
	    syslog($priority, $mesg);
	    closelog();
	}
    }
    unless ($config->{ log_type } =~ /file/) {
	# e.g. log_type = syslog (== syslog only)
	return;
    }

    # parse arguments
    $log_file = $args->{ log_file } if defined $args->{ log_file };
    $priority = $args->{ priority } if defined $args->{ priority };
    $facility = $args->{ facility } if defined $args->{ facility };
    $level    = $args->{ level }    if defined $args->{ level };

    # reference to "date" object
    eval q{
	use Mail::Message::Date;
	$rdate = new Mail::Message::Date;
    };
    if ($@) {
	croak("Mail::Message::Date not found");
    }

    # open the $file by using FileHandle.pm
    use FileHandle;

    # When the second argument is not defined, use the default log_file.
    my $style  = $config->{ log_format_type }       || 'fml4_compatible';
    my $file   = $log_file || $config->{ log_file } || undef;
    my $fh     = undef;
    my $sender = FML::Credential->sender;

    if (defined $file) {
	my $old_mask = umask(077);
	$fh = new FileHandle ">> $file";
	umask($old_mask);

	$fh = \*STDERR unless $fh;
    }
    else {
	$fh = \*STDERR;
    }

    if (defined $fh) {
	# fml <= 4.x style
	if ($style eq 'fml4_compatible') {
	    print $fh $rdate->{'log_file_style'}, " ", $mesg;
	    print $fh " ($sender)" if defined $sender;
	    print $fh "\n";
	}
	# fml 8.x style
	else {
	    use File::Basename;
	    my $name = basename($0);
	    my $pid  = $config->{ _pid };
	    my $iam  = sprintf("%s[%d]", $name, $pid);
	    print $fh $rdate->{'log_file_style'}, " ", $iam, " ", $mesg;
	    print $fh "\n";
	}
    }
    else {
	croak("cannot open $file");
    }
}


# Descriptions: write message "warn: $msg", call Log() ASAP.
#               send the message into stderr if Log() failed.
#    Arguments: STR($mesg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub LogWarn
{
    my ($mesg, $args) = @_;

    eval q{
	Log("warn: $mesg", $args);
    };
    if ($@) {
	# XXX valid use of STDERR
	print STDERR "warn: ", $mesg, "\n";
    }
}


# Descriptions: write message "error: $msg", call Log() ASAP.
#               send the message into stderr if Log() failed.
#    Arguments: STR($mesg) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub LogError
{
    my ($mesg, $args) = @_;

    eval q{
	Log("error: $mesg", $args);
    };
    if ($@) {
	# XXX valid use of STDERR
	print STDERR "error: ", $mesg, "\n";
    }
}


=head1 SEE ALSO

L<Mail::Message::Date>,
L<FML::Config>,
L<FML::Credential>,

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Log first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
