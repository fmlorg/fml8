#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Queue.pm,v 1.18 2002/09/22 14:57:02 fukachan Exp $
#

package Mail::Delivery::Queue;
use strict;
use Carp;
use vars qw($Counter);
use File::Spec;

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

=head2 C<new($args)>

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

    my $dir = $args->{ directory } || croak("specify directory");
    my $id  = defined $args->{ id } ? $args->{ id } : _new_queue_id();
    $me->{ _directory } = $dir;
    $me->{ _id }        = $id;
    $me->{ _status }    = "new";
    $me->{ _new_qf }    = File::Spec->catfile($dir, "new", $id);
    $me->{ _active_qf } = File::Spec->catfile($dir, "active", $id);

    # queue directory mode
    if (defined $args->{ directory_mode }) {
	$dir_mode = $args->{ directory_mode };
    }

    # infomation for delivery
    $me->{ _info }->{ sender }     =
      File::Spec->catfile($dir, "info", "sender", $id);
    $me->{ _info }->{ recipients } =
      File::Spec->catfile($dir, "info", "recipients", $id);

    for ($dir,
	 File::Spec->catfile($dir, "active"),
	 File::Spec->catfile($dir, "new"),
	 File::Spec->catfile($dir, "deferred"),
	 File::Spec->catfile($dir, "info"),
	 File::Spec->catfile($dir, "info", "sender"),
	 File::Spec->catfile($dir, "info", "recipients")) {
	-d $_ || _mkdirhier($_);
    }

    return bless $me, $type;
}


# Descriptions: mkdir recursively
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


# Descriptions: return new queue identifier
#    Arguments: none
# Side Effects: increment counter $Counter
# Return Value: STR
sub _new_queue_id
{
    $Counter++;
    return time.".$$.$Counter";
}


=head2 C<id()>

return the queue id assigned to the object C<$self>.

=cut


# Descriptions: return object identifier (queue id)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub id
{
    my ($self) = @_;
    $self->{ _id };
}


=head2 C<filename()>

return the file name of the queue id assigned to the object C<$self>.

=cut


# Descriptions: return queue file name assigned to this object
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub filename
{
    my ($self) = @_;
    -f $self->{ _active_qf } ? $self->{ _active_qf } : undef;
}


=head2 C<list()>

return queue list as ARRAY REFERENCE.
It is a list of queue filenames in C<active/> directory.

    $ra = $queue->list();
    for $qid (@$ra) {
	something for $qid ...
     }

where C<$qid> is like this: 990157187.20792.1

=cut


# Descriptions: return queue file list
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub list
{
    my ($self) = @_;
    my $dir = File::Spec->catfile( $self->{ _directory }, "active");

    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	my @r = ();

	while (defined ($_ = $dh->read)) {
	    next unless /^\d+/;
	    push(@r, $_);
	}

	return \@r;
    }

    return [];
}


=head1 METHODS TO MANIPULATE INFORMATION

=head2 C<getidinfo($id)>

return information related with the queue id C<$id>.
The returned information is

	id         => $id,
	path       => "$dir/active/$id",
	sender     => $sender,
	recipients => \@recipients,

=cut


# Descriptions: get information of queue for this object
#    Arguments: OBJ($self) STR($id)
# Side Effects: none
# Return Value: HASH_REF
sub getidinfo
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory };
    my ($fh, $sender, @recipients);

    # validate queue id is given
    $id ||= $self->id();

    # sender
    use FileHandle;
    $fh = new FileHandle File::Spec->catfile($dir, "info", "sender", $id);
    if (defined $fh) {
	$sender = $fh->getline;
	$sender =~ s/[\n\s]*$//;
	$fh->close;
    }

    # recipient array
    $fh = new FileHandle File::Spec->catfile($dir, "info", "recipients", $id);
    if (defined $fh) {
	while (defined( $_ = $fh->getline)) {
	    s/[\n\s]*$//;
	    push(@recipients, $_);
	}
	$fh->close;
    }

    return {
	id         => $id,
	path       => File::Spec->catfile($dir, "active", $id),
	sender     => $sender,
	recipients => \@recipients,
    };
}


=head1 LOCK

=head2 C<lock()>

=head2 C<unlock()>

=cut


use FileHandle;
use Fcntl qw(:DEFAULT :flock);


# Descriptions: lock queue
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: flock queue
# Return Value: 1 or 0
sub lock
{
    my ($self, $args) = @_;
    my $fh   = new FileHandle $self->{ _active_qf };
    my $wait = defined $args->{ wait } ? $args->{ wait } : 10;

    eval {
	local($SIG{ALRM}) = sub { croak("lock timeout");};
        alarm( $wait );
	flock($fh, &LOCK_EX);
	$self->{ _lock }->{ _fh } = $fh;
    };

    ($@ =~ /lock timeout/) ? 0 : 1;
}


# Descriptions: unlock queue
#    Arguments: OBJ($self)
# Side Effects: unlock queue by flock(2)
# Return Value: 1 or 0
sub unlock
{
    my ($self) = @_;
    my $fh = $self->{ _lock }->{ _fh };
    flock($fh, &LOCK_UN);
}


=head2 C<in($msg)>

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
	$msg->print($fh);
	$fh->close;
    }

    return( (-e $qf && -s $qf) ? 1 : 0 );
}


=head2 C<set($key, $args)>

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

    use FileHandle;

    if ($key eq 'sender') {
	my $fh = new FileHandle "> $qf_sender";
	if (defined $fh) {
	    print $fh $value, "\n";
	    $fh->close;
	}
    }
    elsif ($key eq 'recipients') {
	my $fh = new FileHandle "> $qf_recipients";
	if (defined $fh) {
	    for (@$value) { print $fh $_, "\n";}
	    $fh->close;
	}
    }
}


=head2 C<setrunnable()>

set the status of the queue assigned to this object C<$self>
deliverable.
This file is scheduled to be delivered.

In fact, setrunnable() C<rename>s the queue id file from C<new/>
directory to C<active/> directory like C<postfix> queue strategy.

=cut


# Descriptions: set this object queue to be deliverable
#    Arguments: OBJ($self)
# Side Effects: move $queue_id file from new/ to active/
# Return Value: 1 (success) or 0 (fail)
sub setrunnable
{
    my ($self) = @_;
    my $qf_new        = $self->{ _new_qf };
    my $qf_sender     = $self->{ _info }->{ sender };
    my $qf_recipients = $self->{ _info }->{ recipients };

    # There must be a set of these three files.
    unless (-f $qf_new && -f $qf_sender && -f $qf_recipients) {
	return 0;
    }

    # move new/$id to active/$id
    rename( $self->{ _new_qf }, $self->{ _active_qf } );
}



=head2 C<remove()>

remove all queue assigned to this object C<$self>.

=head2 C<valid()>

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

    for ($self->{ _new_qf },
	 $self->{ _active_qf },
	 $self->{ _info }->{ sender },
	 $self->{ _info }->{ recipients }) {
	unlink $_ if -f $_;
    }
}


# Descriptions: this object (queue) is sane ?
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: 1 or 0
sub valid
{
    my ($self) = @_;
    my $ok = 0;

    for ($self->{ _active_qf },
	 $self->{ _info }->{ sender },
	 $self->{ _info }->{ recipients }) {
	$ok++ if -f $_ && -s $_;
    }

    ($ok == 3) ? 1 : 0;
}


# Descriptions: clear this queue file
#    Arguments: OBJ($self)
# Side Effects: unlink this queue
# Return Value: NUM
sub DESTROY
{
    my ($self) = @_;
    unlink $self->{ _new_qf } if -f $self->{ _new_qf };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Delivery::Queue first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
