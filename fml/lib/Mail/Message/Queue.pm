#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML$
#

package Mail::Message::Queue;
use strict;
use Carp;
use vars qw($Counter);

=head1 NAME

Mail::Message::Queue - hashed directory holding queue files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 DIRECTORY STRUCTURE

create a new queue id and file (C<$qid>).

   new/$qid

To permit to be deliverd, move the queue file from new/ to active/ by
C<rename(2)>.

   active/$qid

=head1 METHODS

=head2 C<new($args)>

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

    for ($dir, "$dir/active", "$dir/new") {
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

return the quque id assigned to the object.

=cut

sub id
{
    my ($self) = @_;
    $self->{ _id };
}


=head2 C<queue_file()>

return the file name of the quque id assigned to the object.

=cut

sub queue_file
{
    my ($self) = @_;
    -f $self->{ _active_qf } ? $self->{ _active_qf } : undef;
}


=head2 C<in($msg)>

C<$msg> is C<Mail::Message> object.

=head2 C<activate()>

activate the queue assigned to this object C<$self>.
This file is scheduled to be delivered (in near future).

In fact activate() C<rename>s the queue id file from C<new/> directory
to C<active/> directory like C<postfix> queue strategy.

=head2 C<remove()>

remove all queue assigned to this object C<$self>.

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


# Descriptions: activate this object queue
#    Arguments: $self $args
# Side Effects: move $queue_id file from new/ to active/
# Return Value: 1 (success) or 0 (fail)
sub activate
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

Mail::Message::Queue appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
