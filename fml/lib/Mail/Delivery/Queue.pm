#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Queue.pm,v 1.1 2001/05/09 00:55:54 fukachan Exp $
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

C<new()> assigns the queue id, queue files to be used but do no actual
works.

=cut


sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    my $dir = $args->{ directory } || croak("specify directory");
    my $id  = _new_queue_id();
    $me->{ _directory } = $dir;
    $me->{ _id }        = $id;
    $me->{ _status }    = "new";
    $me->{ _new_qf }    = "$dir/new/$id";
    $me->{ _active_qf } = "$dir/active/$id";

    for ($dir, "$dir/active", "$dir/new", "$dir/deferred", "$dir/info") {
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


=head2 C<in($msg)>

You specify C<$msg>, which is C<Mail::Message> object.
C<in()> creates a queue file in C<new/> directory 
(C<queue_directory/new/>.

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


=head2 C<info($args)>

   $args = {
	sender     => $sender,
	recipients => [ $recipient ],
   }

=head2 C<setrunnable()>

set the status of the queue assigned to this object C<$self>
deliverable. 
This file is scheduled to be delivered.

In fact, setrunnable() C<rename>s the queue id file from C<new/>
directory to C<active/> directory like C<postfix> queue strategy.

=head2 C<remove()>

remove all queue assigned to this object C<$self>.

=cut


# Descriptions: set this object queue to be deliverable 
#    Arguments: $self $args
# Side Effects: move $queue_id file from new/ to active/
# Return Value: 1 (success) or 0 (fail)
sub setrunnable
{
    my ($self) = @_;
    rename( $self->{ _new_qf }, $self->{ _active_qf } );
}


sub remove
{
    my ($self) = @_;
    unlink $self->{ _new_qf }    if -f $self->{ _new_qf };
    unlink $self->{ _active_qf } if -f $self->{ _active_qf };
}


sub DESTROY
{
    my ($self) = @_;
    unlink $self->{ _new_qf }    if -f $self->{ _new_qf };
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
