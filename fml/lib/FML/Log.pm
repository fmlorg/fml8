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
@EXPORT    = qw(Log);
@EXPORT_OK = qw(Log);

use strict;
use Carp;
use FML::Config;
use FML::Date;


#  usage: &Log( message, { logfile => $logfile } );
# return: none
#
sub Log
{
    my ($mesg, $args) = @_;
    my $config = new FML::Config;

    # parse arguments
    my $logfile  = $args->{ logfile };
    my $facility = $args->{ facility };
    my $level    = $args->{ level };

    # invalid calling
    $mesg || return undef ;

    # reference to "date" object
    my $rdate = new FML::Date;

    # open the $file by using FileHandle.pm
    use FileHandle;

    # When the second argument is not defined, use the default logfile.
    my $file = $logfile || $config->{ logfile } || '/dev/stderr';
    my $fh   = new FileHandle ">> $file";

    if (defined $fh) {
	print $fh $rdate->{'logfile_style'}, " ", $mesg, "\n";
    }
    else {
	croak "Error: cannot open $file\n";
    }
}



=head1 NAME

FML::Log.pm - several interfaces to open several files


=head1 SYNOPSIS

To import Log(),

   use FML::Log qw(Log);
   &Log( $log_message );

or specify arguments in the hash reference

   use FML::Log qw(Log);
   &Log( $log_message , { 
       logfile  => $logfile,
       facility => $facility,
       level    => $level,
   });


=head1 DESCRIPTION

FML::Log.pm contains several interfaces for several files,
for example, logfiles, syslog() (not yet implemented).

=item Log( $message )

The argument is the message to log.



=head1 SEE ALSO

L<FML::Date>, 
L<FML::Config>,
L<FML::BaseSystem>,
L<FileHandle>

=head1 AUTHOR

Ken'ichi Fukamachi <F<fukachan@fml.org>>


=head1 COPYRIGHT

Copyright (C) 2000 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 


=head1 HISTORY

FML::Log.pm appeared in fml5.


=cut

1;
