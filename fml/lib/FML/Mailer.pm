#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Mailer.pm,v 1.9 2002/05/22 15:59:57 fukachan Exp $
#

package FML::Mailer;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogError);

=head1 NAME

FML::Mailer - Utilities to send mails

=head1 SYNOPSIS

    use FML::Mailer;
    my $obj = new FML::Mailer;
    $obj->send( {
	sender    => 'rudo@nuinui.net',
	recipient => 'kenken@nuinui.net',
	message   => $message,
    });

where C<$message> is a C<Mail::Message> object to send.
If you want to sent plural recipinets,
specify the recipients as ARRAY HASH at C<recipients> parameter.

    $obj->send( {
	sender     => 'rudo@nuinui.net',
	recipients => [ 'kenken@nuinui.net', 'hitomi@nuinui.net' ],
	message    => $message,
    });

If you send a file, you can specify the filename as a data to send.

    use FML::Mailer;
    my $obj = new FML::Mailer;
    $obj->send( {
	sender    => 'rudo@nuinui.net',
	recipient => 'kenken@nuinui.net',
	file      => "/some/where/file",
    });

=head1 DESCRIPTION

It sends Mail::Message object.

=head1 METHODS

=head2 C<new()>

standard constructor.

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 C<send($args)>

send the given C<message>.
$args can take the following arguments:

   ----------------------------------
   sender             string
   recipient          string
   recipients         HASH ARRAY
   message            Mail::Message object
   file               string

=cut


# Descriptions: send messages in the queue (queue flush).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: queue changed
# Return Value: 1 or 0
sub send
{
    my ($self, $args) = @_;
    my ($config, $maintainer, $fp, $sfp) = ();
    my $handle = undef;

    # $curproc is given in usual fml processes.
    # but not in other programs.
    if (defined $args->{ curproc }) {
	$config     = $args->{ curproc }->{ config } || undef;
	$maintainer = $config->{ maintainer };

	$fp  = sub { Log(@_);}; # pointer to the log function
	$sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
	$handle = \*STDOUT;

	my $curproc = $args->{ curproc };
	my $wh      = $curproc->open_outgoing_message_channel();
	if (defined $wh) {
	    $sfp = sub { print $wh @_;};
	    $handle = $wh;
	}
    }

    # who is sender
    my $sender     = $args->{ sender } || $maintainer;

    # recipient(s): expected to be given as string or HASH ARRAY
    my $recipient  = $args->{ recipient }  || undef;
    my $recipients = $args->{ recipients } || [ $recipient ] || undef;

    # validate input argument
    if ((defined($recipient) && ref($recipient) ne '') ||
	(defined($recipients) && (ref($recipients)) ne 'ARRAY') ||
	(not defined($args->{ message }))) {
	return 0;
    }


    # Mail::Message object which is sent
    my $message    = $args->{ message } || undef;
    my $file       = $args->{ file }    || undef;

    if ($file && -f $file) {
	use Mail::Message;
	use FileHandle;
	my $fh   = new FileHandle $file;
	$message = Mail::Message->parse( { fd => $fh } );
    }

    ### main ###
    use Mail::Delivery;
    my $service = new Mail::Delivery {
	log_function       => $fp,
	smtp_log_function  => $sfp,
	smtp_log_handle    => $handle,
    };
    if ($service->error) { LogError($service->error); return 0;}

    $service->deliver({
	'smtp_sender'     => $sender,
	'recipient_array' => $recipients,
	'message'         => $message,
    });
    if ($service->error) { LogError($service->error); return 0;}

    return 1;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Mailer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
