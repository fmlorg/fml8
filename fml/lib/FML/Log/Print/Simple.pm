#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: @template.pm,v 1.7 2003/01/01 02:06:22 fukachan Exp $
#

package FML::Log::Print::Simple;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Log::Print::Simple - simplest engine

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
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


# Descriptions: add message to message queue
#    Arguments: OBJ($self) OBJ($msg)
# Side Effects: none
# Return Value: none
sub add
{
    my ($self, $msg) = @_;
    my $queue = $self->{ _queue };
    $queue->append($msg);
}


# Descriptions: output
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub print
{
    my ($self)   = @_;
    my $queue = $self->{ _queue };
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

__YOUR_NAME__

=head1 COPYRIGHT

Copyright (C) 2003 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Log::Print::Simple appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
