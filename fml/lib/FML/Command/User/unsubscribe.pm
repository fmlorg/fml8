#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: unsubscribe.pm,v 1.1.1.1 2001/08/26 05:43:10 fukachan Exp $
#

package FML::Command::User::unsubscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);

=head1 NAME

FML::Command::User::unsubscribe - remove the specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 METHODS

=head2 C<process($curproc, $optargs)>

=cut


sub process
{
    my ($self, $curproc, $optargs) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $optargs->{ options };
    my $address       = $optargs->{ address } || $options->[ 0 ];

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use IO::Adapter;
    my $obj = new IO::Adapter $member_map;
    $obj->delete( $address );

    $obj = new IO::Adapter $recipient_map;
    $obj->delete( $address );
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::unsubscribe appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
