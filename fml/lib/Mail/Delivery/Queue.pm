#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Queue.pm,v 1.36 2004/05/24 15:18:33 fukachan Exp $
#

package Mail::Delivery::Queue;
use strict;
use Carp;
use vars qw($Counter);
use File::Spec;
use Mail::Delivery::ErrorStatus qw(error_set error error_clear);


=head1 NAME

Mail::Delivery::Queue - hashed directory holding queue files

=head1 SYNOPSIS

    use Mail::Message;
    $msg = new Mail::Message;

    use Mail::Delivery::Queue;
    my $queue = new Mail::Delivery::Queue { directory => "/some/where" };

    # queue in a new message
    # "/some/where/new/$queue_id" is created.
    $queue->in( $msg ) || croak("fail to queue in");

    # ok to deliver this message !
    $queue->setrunnable() || croak("fail to set queue deliverable");

    # get the filename of this $queue object
    my $filename = $queue->filename();

=head1 DESCRIPTION

C<Mail::Delivery::Queue> provides basic manipulation of mail queue.

=head1 DIRECTORY STRUCTURE

C<new()> method assigns a new queue id C<$qid> and filename C<$qf> but
not do actual works.

C<in()> method creates a new queue file C<$qf>. So, C<$qf> follows:

   $qf = "$queue_dir/new/$qid"

When C<$qid> is prepared to be deliverd, you must move the queue file
from new/ to active/ by C<rename(2)>. You can do it by C<setrunnable()>
method.

   $queue_dir/new/$qid  --->  $queue_dir/active/$qid

The actual delivery is done by other modules such as
C<Mail::Delivery>.
C<Mail::Delivery::Queue> manipulats only queue around things.

=head1 METHODS

=head2 new($args)

constructor. You must specify C<queue directory> as

    $args->{ dirctory } .

If C<id> is not specified,
C<new()> assigns the queue id, queue files to be used.
C<new()> assigns them but do no actual works.

=cut


my $dir_mode = 0755;


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: initialize object
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    # XXX-TODO: _status is used ?
    my $dir = $args->{ directory } || croak("specify directory");
    my $id  = defined $args->{ id } ? $args->{ id } : _new_queue_id();
    $me->{ _directory } = $dir;
    $me->{ _id }        = $id;
    $me->{ _status }    = "new";

    # bless !
    bless $me, $type;

    # update queue directory mode
    $dir_mode = $args->{ directory_mode } || $dir_mode;

    # prepare directories
    my $new_dir       = $me->new_dir_path($id);
    my $info_dir      = $me->info_dir_path($id);
    my $active_dir    = $me->active_dir_path($id);
    my $incoming_dir  = $me->incoming_dir_path($id);
    my $sender_dir    = $me->sender_dir_path($id);
    my $rcpt_dir      = $me->recipients_dir_path($id);
    my $deferred_dir  = $me->deferred_dir_path($id);
    my $transport_dir = $me->transport_dir_path($id);

    # hold information for delivery
    $me->{ _new_qf }               = $me->new_file_path($id);
    $me->{ _active_qf }            = $me->active_file_path($id);
    $me->{ _incoming_qf }          = $me->incoming_file_path($id);
    $me->{ _info }->{ sender }     = $me->sender_file_path($id);
    $me->{ _info }->{ recipients } = $me->recipients_file_path($id);
    $me->{ _info }->{ transport }  = $me->transport_file_path($id);

    # create directories in queue if not exists.
    for my $_dir ($dir, $active_dir, $incoming_dir, $new_dir, $info_dir,
		  $deferred_dir, $sender_dir, $rcpt_dir,
		  $transport_dir) {
	-d $_dir || _mkdirhier($_dir);
    }

    return bless $me, $type;
}


# Descriptions: mkdir recursively.
#    Arguments: STR($dir)
# Side Effects: none
# Return Value: ARRAY or UNDEF
sub _mkdirhier
{
    my ($dir) = @_;

    eval q{
	use File::Path;
	mkpath( [ $dir ], 0, $dir_mode);
    };
    warn($@) if $@;
}


# Descriptions: return new queue identifier.
#    Arguments: none
# Side Effects: increment counter $Counter
# Return Value: STR
sub _new_queue_id
{
    $Counter++;
    return time.".$$.$Counter";
}


=head2 id()

return the queue id assigned to this object C<$self>.

=cut


# Descriptions: return object identifier (queue id).
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub id
{
    my ($self) = @_;
    $self->{ _id };
}


=head2 filename()

return the file name of the queue id assigned to this object C<$self>.

=cut


# Descriptions: return queue file name assigned to this object.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub filename
{
    my ($self) = @_;
    -f $self->{ _active_qf } ? $self->{ _active_qf } : undef;
}


=head2 list()

return queue list as ARRAY REFERENCE.
It is a list of queue filenames in C<active/> directory.

    $ra = $queue->list();
    for $qid (@$ra) {
	something for $qid ...
     }

where C<$qid> is like this: 990157187.20792.1

=cut


# Descriptions: return queue file list.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub list
{
    my ($self) = @_;
    my $dir = $self->active_dir_path();

    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my @r = ();
	my $file;

      ENTRY:
	while (defined ($file = $dh->read)) {
	    next ENTRY unless $file =~ /^\d+/o;
	    push(@r, $file);
	}

	return \@r;
    }

    return [];
}


=head1 METHODS TO MANIPULATE INFORMATION

=head2 getidinfo($id)

return information related with the queue id C<$id>.
The returned information is

	id         => $id,
	path       => "$dir/active/$id",
	sender     => $sender,
	recipients => \@recipients,

=cut


# Descriptions: get information of queue for this object.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: HASH_REF
sub getidinfo
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory };
    my ($fh, $sender, @recipients);

    # validate if the queue id is given
    $id ||= $self->id();

    # sender
    use FileHandle;
    $fh = new FileHandle $self->sender_file_path($id);
    if (defined $fh) {
	$sender = $fh->getline;
	$sender =~ s/[\n\s]*$//o;
	$fh->close;
    }

    # recipient array
    $fh = new FileHandle $self->recipients_file_path($id);
    if (defined $fh) {
	my $buf;

      ENTRY:
	while (defined($buf = $fh->getline)) {
	    $buf =~ s/[\n\s]*$//o;
	    push(@recipients, $buf);
	}
	$fh->close;
    }

    return {
	id         => $id,
	path       => $self->active_file_path($id),
	sender     => $sender,
	recipients => \@recipients,
    };
}


=head1 LOCK

=head2 lock()

=head2 unlock()

=cut


use FileHandle;
use Fcntl qw(:DEFAULT :flock);


# Descriptions: lock queue.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: flock queue
# Return Value: 1 or 0
sub lock
{
    my ($self, $args) = @_;
    my $wait = defined $args->{ wait } ? $args->{ wait } : 10;
    my $prep = defined $args->{ lock_before_runnable } ? 1 : 0;
    my $file = $prep ? $self->{ _new_qf } : $self->{ _active_qf };
    my $fh   = new FileHandle $file;

    eval {
	local($SIG{ALRM}) = sub { croak("lock timeout");};
        alarm( $wait );
	flock($fh, &LOCK_EX);
	$self->{ _lock }->{ _fh } = $fh;
    };
    alarm(0);

    ($@ =~ /lock timeout/o) ? 0 : 1;
}


# Descriptions: unlock queue.
#    Arguments: OBJ($self)
# Side Effects: unlock queue by flock(2)
# Return Value: 1 or 0
sub unlock
{
    my ($self) = @_;
    my $fh = $self->{ _lock }->{ _fh };
    flock($fh, &LOCK_UN);
}


=head2 in($msg)

C<in()> creates a queue file in C<new/> directory
(C<queue_directory/new/>.

C<$msg> is C<Mail::Message> object by default.
If C<$msg> object has print() method,
arbitrary C<$msg> is acceptable.

REMEMBER YOU MUST DO C<setrunnable()> for the queue to deliver.
If you not C<setrunnable()> it, the queue file is removed by
C<DESTRUCTOR>.

=cut


# Descriptions: create a new queue file.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: 1 or 0
sub in
{
    my ($self, $msg) = @_;
    my $qf = $self->{ _new_qf };

    use FileHandle;
    my $fh = new FileHandle "> $qf";
    if (defined $fh) {
	$fh->autoflush(1);
	$fh->clearerr();
	$msg->print($fh);
	if ($fh->error()) {
	    $self->error_set("write error");
	}
	$fh->close;
    }

    # check the existence and the size > 0.
    return( (-e $qf && -s $qf) ? 1 : 0 );
}


=head2 set($key, $args)

   $queue->set('sender', $sender);
   $queue->set('recipients', [ $recipient0, $recipient1 ] );

It sets up delivery information in C<info/sender/> and
C<info/recipients/> directories.

=cut


# Descriptions: set value for key
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: same as close()
sub set
{
    my ($self, $key, $value) = @_;
    my $qf_sender     = $self->{ _info }->{ sender };
    my $qf_recipients = $self->{ _info }->{ recipients };
    my $qf_transport  = $self->{ _info }->{ transport };

    use FileHandle;

    if ($key eq 'sender') {
	my $fh = new FileHandle "> $qf_sender";
	if (defined $fh) {
	    $fh->clearerr();
	    print $fh $value, "\n";
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'recipients') {
	my $fh = new FileHandle ">> $qf_recipients";
	if (defined $fh) {
	    $fh->clearerr();
	    if (ref($value) eq 'ARRAY') {
		for my $rcpt (@$value) { print $fh $rcpt, "\n";}
	    }
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'recipient_maps') {
	my $fh = new FileHandle ">> $qf_recipients";
	if (defined $fh) {
	    $fh->clearerr();

	    if (ref($value) eq 'ARRAY') {
		for my $map (@$value) {
		    use IO::Adapter;
		    my $obj = new IO::Adapter $map;
		    if (defined $obj) {
			$obj->open();

			my $buf;
			while ($buf = $obj->get_next_key()) {
			    print $fh $buf, "\n";
			}
			$obj->close();
		    }
		}
	    }

	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
    elsif ($key eq 'transport') {
	my $fh = new FileHandle "> $qf_transport";
	if (defined $fh) {
	    $fh->clearerr();
	    print $fh $value, "\n";
	    if ($fh->error()) {
		$self->error_set("write error");
	    }
	    $fh->close;
	}
    }
}


=head2 setrunnable()

set the status of the queue assigned to this object C<$self>
deliverable.
This file is scheduled to be delivered.

In fact, setrunnable() C<rename>s the queue id file from C<new/>
directory to C<active/> directory like C<postfix> queue strategy.

=cut


# Descriptions: enable this object queue to be delivery ready.
#    Arguments: OBJ($self)
# Side Effects: move $queue_id file from new/ to active/
# Return Value: 1 (success) or 0 (fail)
sub setrunnable
{
    my ($self)        = @_;
    my $qf_new        = $self->{ _new_qf };
    my $qf_sender     = $self->{ _info }->{ sender };
    my $qf_recipients = $self->{ _info }->{ recipients };

    # something error.
    if ($self->error()) {
	warn( $self->error() );
	return 0;
    }

    # There must be a set of these three files.
    # 1. exisntence
    unless (-f $qf_new && -f $qf_sender && -f $qf_recipients) {
	return 0;
    }
    # 2. non-zero size.
    unless (-s $qf_new && -s $qf_sender && -s $qf_recipients) {
	return 0;
    }

    # move new/$id to active/$id
    if (rename( $self->{ _new_qf }, $self->{ _active_qf } )) {
	return 1;
    }

    return 0;
}


=head2 remove()

remove all queue assigned to this object C<$self>.

=head2 valid()

It checks the queue file is broken or not.
return 1 (valid) or 0.

=cut


# Descriptions: remove queue files for this object (queue)
#    Arguments: OBJ($self)
# Side Effects: remove queue file(s)
# Return Value: none
sub remove
{
    my ($self) = @_;

    for my $f ($self->{ _new_qf },
	       $self->{ _active_qf },
	       $self->{ _incoming_qf },
	       $self->{ _info }->{ sender },
	       $self->{ _info }->{ recipients },
	       $self->{ _info }->{ transport }) {
	unlink $f if -f $f;
    }
}


# Descriptions: this object (queue) is sane as active queue?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub valid_active_queue
{
    my ($self) = @_;
    my $ok = 0;

    for my $f ($self->{ _active_qf },
	       $self->{ _info }->{ sender },
	       $self->{ _info }->{ recipients }) {
	$ok++ if -f $f && -s $f;
    }

    ($ok == 3) ? 1 : 0;
}


# Descriptions: clear this queue file.
#    Arguments: OBJ($self)
# Side Effects: unlink this queue
# Return Value: NUM
sub DESTROY
{
    my ($self) = @_;

    unlink $self->{ _new_qf } if -f $self->{ _new_qf };
}


=head1 UTILITIES

=cut


# Descriptions: return "new" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub new_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "new", $id);
}


# Descriptions: return "deferred" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub deferred_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "deferred", $id);
}


# Descriptions: return "active" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub active_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "active", $id);
}


# Descriptions: return "incoming" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub incoming_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "incoming", $id);
}


# Descriptions: return "info" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub info_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", $id);
}


# Descriptions: return "sender" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub sender_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "sender", $id);
}


# Descriptions: return "recipients" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub recipients_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "recipients", $id);
}


# Descriptions: return "transport" file path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub transport_file_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "transport", $id);
}


# Descriptions: return "new" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub new_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "new");
}


# Descriptions: return "deferred" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub deferred_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "deferred");
}


# Descriptions: return "active" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub active_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "active");
}


# Descriptions: return "incoming" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub incoming_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "incoming");
}


# Descriptions: return "info" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub info_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info");
}


# Descriptions: return "sender" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub sender_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "sender");
}


# Descriptions: return "recipients" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub recipients_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "recipients");
}


# Descriptions: return "transport" directory path.
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: STR
sub transport_dir_path
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory } || croak("directory undefined");

    return File::Spec->catfile($dir, "info", "transport");
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

Mail::Delivery::Queue first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
