#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Mailer.pm,v 1.38 2006/04/05 11:39:11 fukachan Exp $
#

package FML::Mailer;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Mailer - utilities for sending mails.

=head1 SYNOPSIS

    use FML::Mailer;
    my $obj = new FML::Mailer;
    $obj->send( {
	sender    => 'rudo@nuinui.net',
	recipient => 'kenken@nuinui.net',
	message   => $message,
    });

where C<$message> is a C<Mail::Message> object to send.
If you want to sent to plural recipinets,
specify the recipients as ARRAY REFERENCE at C<recipients> parameter.

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

This module sends Mail::Message object(s).

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 send($send_args)

send the given C<message>.
$send_args (HASH_REF) can take the following arguments:

   ----------------------------------
   sender             STR
   recipient          STR
   recipients         ARRAY_REF
   message            Mail::Message OBJ
   file               STR

=cut


# Descriptions: send messages in the queue (queue flush).
#    Arguments: OBJ($self) OBJ($queue) HASH_REF($send_args)
# Side Effects: queue changed
# Return Value: NUM(1 or 0)
sub send
{
    my ($self, $queue, $send_args) = @_;
    my $handle       = undef;
    my $fp_log_info  = undef;
    my $fp_log_error = undef;
    my $fp_log_debug = undef;
    my $fp_smtplog   = undef;
    my $maintainer   = undef;
    my $curproc      = $self->{ _curproc };

    # 0. fundamental environment
    #    $curproc is given in usual fml processes.
    #    but not in other programs.
    if (defined $curproc) {
	my $config  = $curproc->config();
	$maintainer = $config->{ maintainer } if defined $config;

	# default log functions
	$fp_log_info  = sub { $curproc->log(@_);};
	$fp_log_error = sub { $curproc->logerror(@_);};
	$fp_log_debug = sub { $curproc->logdebug(@_);};
	$fp_smtplog   = sub {
	    my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;
	};

	# overwrite smtp log channel
	$handle = \*STDOUT;
	my $wh  = $curproc->outgoing_message_cache_open();
	if (defined $wh) {
	    $fp_smtplog = sub { print $wh @_;};
	    $handle     = undef ; # $wh; # to avoid log duplication.
	}
    }
    else {
	$curproc->logerror("FML::Mailer: curproc not specified");
	return 0;
    }

    # 1. sender
    my $sender = $send_args->{sender} || $maintainer || '';
    unless ($sender) {
	$curproc->logerror("FML::Mailer: no sender");
	return 0;
    }

    # 2. recipient(s)
    my $maps = $send_args->{ recipient_maps } || undef;
    unless ($maps) {
	$curproc->logerror("FML::Mailer: no recipient(s)");
	return 0;
    }

    # 3. message
    my $message = undef;

    # 3.1 message object
    if (defined($send_args->{ message }) && ref($send_args->{ message })) {
	$message = $send_args->{ message };
    }
    else {
	$curproc->logerror("FML::Mailer: no message");
	return 0;
    }

    # 3.2 file
    if (defined($send_args->{ file })) {
	my $file = $send_args->{ file };
	if ($file && -f $file) {
	    use Mail::Message;
	    use FileHandle;
	    my $fh   = new FileHandle $file;
	    $message = Mail::Message->parse( { fd => $fh } );
	}
	else {
	    $curproc->logerror("FML::Mailer: no such file ($file)");
	}
    }

    unless (defined $message) {
	$curproc->logerror("FML::Mailer: no message");
	return 0;
    }

    # address validater
    my $validater = sub {
	my ($address) = @_;
	use FML::Restriction::Base;
	my $restriction = new FML::Restriction::Base;
	return $restriction->regexp_match( 'address', $address );
    };

    #
    # main
    #
    my $config = $curproc->config();
    my $queue_dir = $config->{ mail_queue_dir };

    use Mail::Delivery;
    my $service = new Mail::Delivery {
	log_info_function  => $fp_log_info,
	log_error_function => $fp_log_error,
	log_debug_function => $fp_log_debug,
	smtp_log_function  => $fp_smtplog,
	smtp_log_handle    => $handle,
	address_validate_function => $validater,
    };
    if ($service->error) { $curproc->logerror($service->error); return 0;}

    $service->deliver({
	'smtp_servers'    => $config->{'smtp_servers'},

	'smtp_sender'     => $sender,
	'recipient_maps'  => $maps,
	'recipient_limit' => $config->{smtp_recipient_limit},

	'message'         => $message,
	map_params        => $config,

	queue             => $queue,

	# XXX do not need fallback here ?
        use_queue_dir     => 1,
        queue_dir         => $queue_dir,
    });
    if ($service->error) { $curproc->logerror($service->error); return 0;}

    # delivery not completes.
    if ($service->get_not_done()) {
	$curproc->logdebug("delivery not done");
	return 0;
    }

    return 1;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Mailer first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
