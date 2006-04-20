#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: QueueManager.pm,v 1.41 2006/04/05 12:54:26 fukachan Exp $
#

package FML::Process::QueueManager;

use strict;
use Carp;

=head1 NAME

FML::Process::QueueManager - provide queue manipulation functions.

=head1 SYNOPSIS

To flush all entries in the queue,

    use FML::Process::QueueManager;
    my $qmgr_args = { directory => $queue_dir };
    my $queue     = new FML::Process::QueueManager $curproc, $qmgr_args;
    $queue->send($curproc);

or if you send specific queue C<$queue_id>, use

    $queue->send($curproc, $queue_id);

where C<$queue_id> is queue id such as 1000390413.14775.1,
not file path.

=head1 DESCRIPTION

queue flush!

=head1 METHODS

=head2 new($qmgr_args)

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($qmgr_args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $qmgr_args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    $me->{ _curproc   } = $curproc;
    $me->{ _directory } = $qmgr_args->{ directory };

    return bless $me, $type;
}


=head2 send( [ $id ] )

try to send all messages in the queue. If the queue id C<$id> is
specified, send only the queue corresponding to C<$id>.

=cut


# Descriptions: send message(s) in queue directory sequentially.
#    Arguments: OBJ($self) STR($id)
# Side Effects: queue flush-ed
# Return Value: none
sub send
{
    my ($self, $id) = @_;
    my $curproc     = $self->{ _curproc };
    my $queue_dir   = $self->{ _directory };
    my $max_count   = 100;
    my $count       = 0;
    my $count_ok    = 0;
    my $count_err   = 0;
    my $channel     = 'qmgr_reschedule';
    my $fp_log      = sub { $curproc->log(@_);};
    my $fp_logerror = sub { $curproc->logerror(@_);};
    my $fp_logdebug = sub { $curproc->logdebug(@_);};

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    $queue->set_log_function($fp_log);
    $queue->set_log_error_function($fp_logerror);
    $queue->set_log_debug_function($fp_logdebug);

    my $ra    = [];
    if (defined $id) {
	$ra = [ $id ];
    }
    else {
	# XXX-TODO: customizable
	$queue->set_policy("fair-queue");
	$ra = $queue->list();
	unless (@$ra) {
	    $curproc->logdebug("qmgr: empty active queue. re-schedule");
	    $queue->reschedule();
	    $ra = $queue->list();
	}
    }

  QUEUE:
    for my $qid (@$ra) {
	last QUEUE if $curproc->is_process_time_limit();

	my $q = new Mail::Delivery::Queue {
	    id        => $qid,
	    directory => $queue_dir,
	};
	$q->set_log_info_function($fp_log);
	$q->set_log_error_function($fp_logerror);
	$q->set_log_debug_function($fp_logdebug);

	# check before try lock (XXX not enough check)
	unless ($q->is_valid_active_queue()) {
	    next QUEUE;
	}

	if ( $q->lock( { wait => 10 } ) && $q->is_valid_active_queue() ) {
	    $curproc->logdebug("qmgr: got lock qid=$qid");

	    my $is_locked = 1;

	    if ( $q->is_valid_active_queue() ) {
		my $r = $self->_send($q);
		if ($r) {
		    $q->remove();
		    $count_ok++;
		}
		else {
		    $curproc->logdebug("qmgr: qid=$qid try later.");
		    $q->unlock();
		    $q->sleep_queue();
		    $is_locked = 0;
		    $count_err++;
		}
		$count++;
	    }
	    else {
		# XXX-TODO: $q->remove() if invalid queue ?
		$curproc->logerror("qmgr: qid=$qid is invalid");
	    }

	    $q->unlock() if $is_locked;
	}
	else {
	    $curproc->logdebug("qmgr: qid=$qid is locked or invalid. retry");
	}

	# upper limit of processing done on one process.
	last QUEUE if $count >= $max_count;
    }

    if ($count) {
	$curproc->logdebug("qmgr: total=$count ok=$count_ok error=$count_err");
    }

    if ($curproc->is_event_timeout($channel)) {
	if (defined $queue) {
	    $curproc->logdebug("qmgr: re-schedule");
	    $queue->reschedule();
	}
	# XXX-TODO: customizable
	$curproc->event_set_timeout($channel, time + 300);
    }
}


# Descriptions: send message object $q.
#    Arguments: OBJ($self) OBJ($q)
# Side Effects: queue flush-ed
# Return Value: STR
sub _send
{
    my ($self, $q)    = @_;
    my $curproc       = $self->{ _curproc };
    my $qid           = $q->id();
    my $qf_act        = $q->active_file_path($qid);
    my $recipient_map = $q->recipients_file_path($qid);
    my $sender        = $q->get_sender($qid);

    use Mail::Message;
    my $msg = Mail::Message->parse( { file => $qf_act } );

    # XXX lock for recipient maps is NOT needed since already a copy.
    # XXX queue is already locked and need no lock for recipient maps here.
    use FML::Mailer;
    my $mailwrapper = new FML::Mailer $curproc;
    my $r = $mailwrapper->send($q, {
	sender         => $sender,
	recipient_maps => $recipient_map,
	message        => $msg,
    });

    if ($r) {
	my $delay = '?';
	if ($qid =~ /^(\d+)\./) { $delay = time - $1;}
	$curproc->log("qmgr: qid=$qid status=sent delay=$delay");
    }
    else {
	$curproc->logerror("qmgr: qid=$qid status=deferred");
    }

    return $r;
}


=head2 cleanup( [ $id ] )

clean up queue directory.

=cut


# Descriptions: clean up directory.
#    Arguments: OBJ($self)
# Side Effects: queue flush-ed
# Return Value: none
sub cleanup
{
    my ($self)      = @_;
    my $curproc     = $self->{ _curproc };
    my $queue_dir   = $self->{ _directory };
    my $fp_log      = sub { $curproc->log(@_);};
    my $fp_logerror = sub { $curproc->logerror(@_);};
    my $fp_logdebug = sub { $curproc->logdebug(@_);};


    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    $queue->set_log_function($fp_log);
    $queue->set_log_error_function($fp_logerror);
    $queue->set_log_debug_function($fp_logdebug);

    # XXX-TODO: customizable. $mail_queue_max_lifetime = 5d ?
    my $list  = $queue->list_all() || [];
    my $limit = 5 * 24 * 3600; # 5 days.
    my $now   = time;

    for my $qid (@$list) {
	my $q = new Mail::Delivery::Queue {
	    id        => $qid,
	    directory => $queue_dir,
	};
	$q->set_log_function($fp_log);
	$q->set_log_error_function($fp_logerror);
	$q->set_log_debug_function($fp_logdebug);

	unless ( $q->is_valid_active_queue() ) {
	    my $mtime = $q->last_modified_time();

	    # enough old.
	    if ($mtime < $now - $limit) {
		$curproc->logdebug("qmgr: remove too old queue qid=$qid");
		$q->remove();
	    }
	}
    }
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

FML::Process::QueueManager first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
