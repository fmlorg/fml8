#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Queue.pm,v 1.1 2003/08/30 00:14:44 fukachan Exp $
#

package FML::IPC::Queue;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::IPC::Queue - basic message queue operation

=head1 SYNOPSIS

    my $queue = new FML::IPC::Queue;

    my $msg = new UserDefinedMessageObject { .. } # user defined object.
    $queue->add($msg);

    my $qlist = $queue->list();
    for my $m (@$qlist) { $m->print();}

=head1 DESCRIPTION

FML::IPC::Queue provides basic message queue operations such as
appending messages into the queue,
list up queue et.al.

=head1 METHODS

=head2 new()

=head2 append($msg)

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create an object
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $queue  = [];
    my $me     = { _queue => $queue };
    return bless $me, $type;
}


# Descriptions: append user defined message $msg into the message queue.
#    Arguments: OBJ($self) VAR_ARGS($msg)
# Side Effects: update message queue $self->{ _queue }
# Return Value: none
sub append
{
    my ($self, $msg) = @_;
    my $q = $self->{ _queue };
    push(@$q, $msg);
}


# Descriptions: return the queue as ARRAY_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub list
{
    my ($self) = @_;
    return $self->{ _queue };
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::IPC::Queue appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
