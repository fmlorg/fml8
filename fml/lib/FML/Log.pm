#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#
# $Id$
# $FML$
#

package FML::Log;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(Log LogWarn LogError);

use strict;
use Carp;
use FML::Config;
use FML::Date;
use FML::Credential;

=head1 NAME

FML::Log - several interfaces to open several files

=head1 SYNOPSIS

To import Log(),

   use FML::Log qw(Log LogWarn LogError);
   &Log( $log_message );

or specify arguments in the hash reference

   use FML::Log qw(Log LogWarn LogError);
   &Log( $log_message , { 
       log_file => $log_file,
       priority => $priority,
       facility => $facility,
       level    => $level,
   });


=head1 DESCRIPTION

FML::Log.pm contains several interfaces for several files,
for example, log files, syslog() (not yet implemented).

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

=head2 LogWarn( $message [, $args])

same as Log("warn: $message", $args);

=head2 LogError( $message [, $args])

same as Log("error: $message", $args);

=cut


sub Log
{
    my ($mesg, $args) = @_;
    my $config = new FML::Config;

    # parse arguments
    my $log_file = $args->{ log_file };
    my $priority = $args->{ priority };
    my $facility = $args->{ facility };
    my $level    = $args->{ level };

    # invalid calling
    $mesg || return undef ;

    # reference to "date" object
    my $rdate = new FML::Date;

    # open the $file by using FileHandle.pm
    use FileHandle;

    # When the second argument is not defined, use the default log_file.
    my $style  = $config->{ log_format_type }       || 'fml4_compatible';
    my $file   = $log_file || $config->{ log_file } || '/dev/stderr';
    my $fh     = new FileHandle ">> $file";
    my $sender = FML::Credential->sender;

    if (defined $fh) {
	if ($style eq 'fml4_compatible') {
	    print $fh $rdate->{'log_file_style'}, " ", $mesg;
	    print $fh " ($sender)" if defined $sender;
	    print $fh "\n";
	}
	else {
	    my $name = $0; $name =~ s@.*/@@;
	    my $iam  = $name."[". $config->{ pid } ."]";
	    print $fh $rdate->{'log_file_style'}, " ", $iam, " ", $mesg;
	    print $fh "\n";
	}
    }
    else {
	croak("cannot open $file");
    }
}


sub LogWarn
{
    my ($mesg, $args) = @_;
    Log("warn: ".$mesg, $args);
}


sub LogError
{
    my ($mesg, $args) = @_;
    Log("error: ".$mesg, $args);
}


=head1 SEE ALSO

L<FML::Date>, 
L<FML::Config>,
L<FML::Credential>,

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>

=head1 COPYRIGHT

Copyright (C) 2000 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Log appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
