#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Simple.pm,v 1.5 2004/07/23 13:16:39 fukachan Exp $
#

package FML::Log::Print::Simple;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Log::Print::Simple - simplest print out engine.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: prepare queue object.
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    use FML::IPC::Queue;
    $me->{ _queue } = new FML::IPC::Queue;

    return bless $me, $type;
}


=head2 add($msg)

add message to module internal message queue.

=cut


# Descriptions: add message to module internal message queue.
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: update queue.
# Return Value: none
sub add
{
    my ($self, $msg) = @_;
    my $queue = $self->{ _queue };
    $queue->append($msg);
}


=head2 print()

print message in the internal queue.

=cut


# Descriptions: print out to STDOUT.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self)   = @_;
    my $queue    = $self->{ _queue };
    my $msg_list = $queue->list();
    my ($buf);

    for my $m (@$msg_list) {
	$buf = $m->{ buf } || '';
	$buf =~ s/\n/ /g;
	printf "%10d %5s %s\n", $m->{ time }, $m->{ level }, $buf;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Log::Print::Simple appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
