#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: unsubscribe.pm,v 1.3 2001/10/14 00:44:40 fukachan Exp $
#

package FML::Command::Admin::unsubscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::Admin::unsubscribe - remove the specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $command_args->{ options };
    my $address       = $command_args->{ address } || $options->[ 0 ];

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use IO::Adapter;
    use FML::Log qw(Log LogWarn LogError);

    for my $map ($member_map, $recipient_map) {
	my $obj = new IO::Adapter $map;
	$obj->delete( $address );
	unless ($obj->error()) {
	    Log("removed $address from map=$map");
	}
	else {
	    LogError("fail to remove $address from map=$map");
	}
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::unsubscribe appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
