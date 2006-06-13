#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: SMTP.pm,v 1.2 2006/06/12 22:49:46 fukachan Exp $
#

package TinyMTA::SMTP;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

TinyMTA::SMTP - smtp

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($config)
# Side Effects: 
# Return Value: none
sub new
{
    my ($self, $config) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _config => $config };
    return bless $me, $type;
}


# Descriptions: main routine.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub run
{
    my ($self) = @_;
    my $config = $self->{ _config };

    my $q_list = $self->pickup_queue();
    for my $q (@$q_list) {
	$self->log("try to send: $q");
	$self->send($q);
    }

    $self->resend();
}


# Descriptions: pick up queue (id's) and return it as ARRAY_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub pickup_queue
{
    my ($self) = @_;
    my $config = $self->{ _config };

    my (@queue) = ();  

    use DirHandle;
    my $queue_dir = $config->{ queue_dir };
    my $dh = new DirHandle $queue_dir;
    if (defined $dh) {
	my $entry;

      ENTRY:
	while ($entry = $dh->read()) {
	    next ENTRY if $entry =~ /^\./o;
	    next ENTRY if $entry =~ /^\,/o;
	    next ENTRY if $entry =~ /^\_/o;
	    next ENTRY if $entry !~ /^\d/o;

	    push(@queue, $entry);
	}

	$dh->close();
    }
    else {
	$self->logerror("cannot open $queue_dir");
	croak("cannot open $queue_dir");
    }

    return \@queue;
}


# Descriptions: send queue.
#    Arguments: OBJ($self)
# Side Effects: queue is removed if succeeded.
# Return Value: none
sub send
{
    my ($self, $q) = @_;
    my $qf_candidate = $self->queue_file_path($q);
    my $qf_locked    = $self->queue_file_path("_$q");

    if (rename($qf_candidate, $qf_locked)) {
	$self->_send_file($qf_locked);
	unlink $qf_locked if -f $qf_locked;
    }
    else {
	$self->logerror("cannot lock queue: $q");
    }
}


# Descriptions: return full path for queue id.
#    Arguments: OBJ($self) STR($qid)
# Side Effects: none
# Return Value: STR
sub queue_file_path
{
    my ($self, $qid) = @_;
    my $config       = $self->{ _config };
    my $queue_dir    = $config->{ queue_dir };

    use File::Spec;
    return File::Spec->catfile($queue_dir, $qid);
}


# Descriptions: send $queue_file by Mail::Delivery.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: queue removed if suceeded.
# Return Value: none
sub _send_file
{
    my ($self, $queue_file) = @_;
    my $config    = $self->{ _config };
    my $queue_dir = $config->{ queue_dir };

    use Mail::Message;
    my $message = Mail::Message->parse( { file => $queue_file } );
    unless (defined $message) {
	$self->logerror("undefined message");
	return 0;
    }

    my ($sender, $rcpt_maps) = $self->_analyze_message($message);
    unless ($sender) {
	$self->logerror("no sender");
	return 0;
    }
    unless (@$rcpt_maps) {
	$self->logerror("no recipient");
	return 0;
    }

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };

    my $validater = sub {
	my ($address) = @_; 
	use FML::Restriction::Base;
	my $restriction = new FML::Restriction::Base;
	return $restriction->regexp_match( 'address', $address );
    };

    use Mail::Delivery;
    my $logfp_normal = sub { $self->log(@_); };
    my $logfp_error  = sub { $self->logerror(@_); };
    my $service = new Mail::Delivery {
	log_info_function  => $logfp_normal,
	log_error_function => $logfp_error,
	log_debug_function => undef,
	smtp_log_function  => undef,
	smtp_log_handle    => undef,
	address_validate_function => $validater,
    };
    if ($service->error) { 
	$self->logerror($service->error);
	$self->logerror("cannot initialize Mail::Delivery object");
	return 0;
    }

    $service->deliver({
	'smtp_servers'    => $config->{'smtp_servers'},

	'smtp_sender'     => $sender,
	'recipient_array' => $rcpt_maps,
	'recipient_limit' => $config->{smtp_recipient_limit},

	'message'         => $message,

	queue             => $queue,

	# XXX do not need fallback here ?
        use_queue_dir     => 1,
        queue_dir         => $queue_dir,
    });
    if ($service->error) { 
	$self->logerror($service->error);
	return 0;
    }

    # delivery not completes.
    if ($service->get_not_done()) { 
	$self->logerror("delivery not done");
	return 0;
    }

    # done.
    use File::Basename;
    my $qid = basename($queue_file);
    $qid =~ s/^_//;

    unlink $queue_file;
    unless (-f $queue_file) {
	$self->log("$qid removed");
    }
    else {
	$self->logerror("cannnot remove qid=$qid");
    }

    return 1;
}


# Descriptions: analyze message and return sender and recipients info.
#    Arguments: OBJ($self) STR($msg)
# Side Effects: none
# Return Value: ARRAY(STR, ARRAY_REF)
sub _analyze_message
{
    my ($self, $msg) = @_;
    my $header = $msg->whole_message_header();

    # results
    my ($sender)    = '';
    my ($rcpt_maps) = []; 

    {
	my $from = $header->get('from');
	use Mail::Address;
	my (@addrlist) = Mail::Address->parse($from);
	if (defined $addrlist[0]) {
	    $sender = $addrlist[0]->address;
	}
    }

    {
	my $to   = $header->get('to')  || '';
	my $cc   = $header->get('cc')  || '';
	my $bcc  = $header->get('bcc') || '';
	use Mail::Address;
	my (@addrlist) = Mail::Address->parse("$to, $cc, $bcc");
	if (defined $addrlist[0]) {
	    for my $a (@addrlist) {
		if ($a->address) {
		    push(@$rcpt_maps, $a->address);
		}
	    }
	}
    }

    return($sender, $rcpt_maps);
}


# Descriptions: re-schedule and send old messages.
#    Arguments: OBJ($self)
# Side Effects: old queue removed.
# Return Value: none
sub resend
{
    my ($self)    = @_;
    my $config    = $self->{ _config };
    my $queue_dir = $config->{ queue_dir };

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    $queue->reschedule();
    my $qlist = $queue->list();

    for my $qid (@$qlist) {
	my $q = new Mail::Delivery::Queue { 
	    id        => $qid,
	    directory => $queue_dir,
	};

        if ( $q->lock( { wait => 10 } ) && $q->is_valid_active_queue() ) {
	    my $qf = $q->active_file_path($qid);
	    my $status = $self->_send_file($qf);
	    if ($status) {
		$self->log("status=sent qid=$qid");
		$q->remove();
	    }
	    else {
		$self->logerror("status=deferred qid=$qid");
		$q->remove();
	    } 
	}
    }

    # clean up
    $queue->expire();
}


# Descriptions: log as normal level.
#    Arguments: OBJ($self) STR($msg)
# Side Effects: none
# Return Value: none
sub log
{
    my ($self, $msg) = @_;
    &TinyMTA::Log::log($msg);
}


# Descriptions: log as error level.
#    Arguments: OBJ($self) STR($msg)
# Side Effects: none
# Return Value: none
sub logerror
{
    my ($self, $msg) = @_;
    &TinyMTA::Log::log("error: $msg");
}


######################################################################
#
# dispatcher
#

# Descriptions: main dispatcher.
#    Arguments: OBJ($main_cf) STR($config_cf_file)
# Side Effects: none
# Return Value: none
sub main::dispatch
{
    my ($main_cf, $config_cf_file) = @_;

    my $config = TinyMTA::Config::load_file($config_cf_file, $main_cf);
    my $obj    = new TinyMTA::SMTP $config;
    $obj->run();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

TinyMTA::SMTP appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
