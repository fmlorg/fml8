#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Queue.pm,v 1.5 2001/05/31 11:02:33 fukachan Exp $
#

package Mail::Delivery::Queue;
use strict;
use Carp;
use vars qw($Counter);

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

    # ok to deliver this queue !
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


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    my $dir = $args->{ directory } || croak("specify directory");
    my $id  = $args->{ id } ||  _new_queue_id();
    $me->{ _directory } = $dir;
    $me->{ _id }        = $id;
    $me->{ _status }    = "new";
    $me->{ _new_qf }    = "$dir/new/$id";
    $me->{ _active_qf } = "$dir/active/$id";

    # infomation for delivery
    $me->{ _info }->{ sender }     = "$dir/info/sender/$id";
    $me->{ _info }->{ recipients } = "$dir/info/recipients/$id";

    for ($dir, 
	 "$dir/active", "$dir/new", "$dir/deferred",
	 "$dir/info", "$dir/info/sender", "$dir/info/recipients") {
	-d $_ || _mkdirhier($_);
    }

    return bless $me, $type;
}


sub _mkdirhier
{
    my ($dir) = @_;
    use File::Path;
    mkpath( [ $dir ], 0, 0755);
}


sub _new_queue_id
{
    $Counter++;
    return time.".$$.$Counter";
}


=head2 C<id()>

return the queue id assigned to the object C<$self>.

=cut

sub id
{
    my ($self) = @_;
    $self->{ _id };
}


=head2 C<filename()>

return the file name of the queue id assigned to the object C<$self>.

=cut

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

sub list
{
    my ($self) = @_;
    my $dir = $self->{ _directory }. "/active";
    my @r; # result array which holds active queue list

    use DirHandle;
    my $dh = new DirHandle $dir;
    if (defined $dh) {
	while (defined ($_ = $dh->read)) {
	    next unless /^\d+/;
	    push(@r, $_);
	}
    }

    \@r;
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

sub getidinfo
{
    my ($self, $id) = @_;
    my $dir = $self->{ _directory };
    my ($fh, $sender, @recipients);

    # validate queue id is given
    $id = $id || $self->id();

    # sender
    use FileHandle;
    $fh = new FileHandle "$dir/info/sender/$id";
    if (defined $fh) {
	$sender = $fh->getline;
	$sender =~ s/[\n\s]*$//;
	$fh->close;
    }

    # recipient array
    $fh = new FileHandle "$dir/info/recipients/$id";
    if (defined $fh) {
	while (defined( $_ = $fh->getline)) {
	    s/[\n\s]*$//;
	    push(@recipients, $_);
	}
	$fh->close;
    }

    return {
	id         => $id,
	path       => "$dir/active/$id",
	sender     => $sender,
	recipients => \@recipients,
    };
}


=head1 LOCK

=head2 C<lock()>

=head2 C<unlock()>

=cut

use POSIX qw(EAGAIN ENOENT EEXIST O_EXCL O_CREAT O_RDONLY O_WRONLY); 
use FileHandle;

sub LOCK_SH {1;}
sub LOCK_EX {2;}
sub LOCK_NB {4;}
sub LOCK_UN {8;}


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
#    Arguments: $self $args
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


sub DESTROY
{
    my ($self) = @_;
    unlink $self->{ _new_qf } if -f $self->{ _new_qf };
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Delivery::Queue appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
