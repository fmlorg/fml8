#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: QueueManager.pm,v 1.21 2004/07/23 13:01:29 fukachan Exp $
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

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => $queue_dir };
    my $ra    = defined $id ? [ $id ] : $queue->list();

    for my $qid (@$ra) {
	my $q = new Mail::Delivery::Queue {
	    id        => $qid,
	    directory => $queue_dir,
	};

	if ( $q->lock() ) {
	    if ( $q->valid_active_queue() ) {
		$self->_send($curproc, $q) && $q->remove();
	    }
	    else {
		# XXX-TODO: $q->remove() if invalid queue ?
		$curproc->log("qmgr: qid=$qid is invalid");
	    }
	    $q->unlock();
	}
	else {
	    $curproc->log("qmgr: qid=$qid is locked. retry");
	}
    }
}


# Descriptions: send message object $q.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($q)
# Side Effects: queue flush-ed
# Return Value: STR
sub _send
{
    my ($self, $curproc, $q) = @_;
    my $cred  = $curproc->{ credential };
    my $info  = $q->getidinfo();
    my $qfile = $info->{ 'path' };
    my $qid   = $info->{ 'id' };

    use Mail::Message;
    my $msg = Mail::Message->parse( { file => $qfile } );

    use FML::Mailer;
    my $obj = new FML::Mailer $curproc;

    # XXX-TODO: ? no lock for recipient maps here ???
    # XXX queue is already locked and need no lock for recipient maps here.
    my $r   = $obj->send({
	sender     => $info->{ sender },
	recipients => $info->{ recipients },
	message    => $msg,
	curproc    => $curproc,
    });

    if ($r) {
	$curproc->log("qmgr: qid=$qid status=sent");
    }
    else {
	$curproc->log("qmgr: qid=$qid status=fail");
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
    my ($self)    = @_;
    my $curproc   = $self->{ _curproc };
    my $queue_dir = $self->{ _directory };

    use Mail::Delivery::Queue;
    my $queue   = new Mail::Delivery::Queue { directory => $queue_dir };
    my $classes = $queue->get_class_list() || []; # new, incoming, ...

    for my $class (@$classes) {
	my $ra = $queue->list($class);
	for my $qid (@$ra) {
	    my $q = new Mail::Delivery::Queue {
		id        => $qid,
		directory => $queue_dir,
	    };

	    unless ( $q->is_valid_queue() ) {
		$curproc->log("qmgr: remove invalid queue qid=$qid");
		# $q->remove();
	    }
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::QueueManager first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
