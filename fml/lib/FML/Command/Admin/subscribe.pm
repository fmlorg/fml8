#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: subscribe.pm,v 1.3 2001/09/13 11:53:30 fukachan Exp $
#

package FML::Command::Admin::subscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::Admin::subscribe - subscribe a new member

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

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
    croak("address is not specified")       unless defined $address;
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use IO::Adapter;
    use FML::Credential;
    use FML::Log qw(Log LogWarn LogError);

    for my $map ($member_map, $recipient_map) {
	my $cred = new FML::Credential;
	unless ($cred->has_address_in_map($map, $address)) {
	    my $obj = new IO::Adapter $map;
	    $obj->touch();
	    $obj->add( $address );
	    unless ($obj->error()) {
		Log("added $address to map=$map");
	    }
	    else {
		LogError("fail to add $address to map=$map");
	    }
	}
	else {
	    $self->error_set( "$address is already member (map=$map)" );
	    return undef;
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

FML::Command::Admin::subscribe appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
