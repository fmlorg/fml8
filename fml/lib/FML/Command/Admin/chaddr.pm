#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.11 2002/02/20 14:10:37 fukachan Exp $
#

package FML::Command::Admin::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::Admin::chaddr - chaddr a new member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

chaddr a new address.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: chaddr a new user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $options       = $command_args->{ options };
    my $old_address   = '';
    my $new_address   = '';

    if (defined $command_args->{ command_data }) {
	my $x = $command_args->{ command_data };
	($old_address, $new_address) = split(/\s+/, $x);
    }
    else {
	$old_address = $options->[ 0 ];
	$new_address = $options->[ 1 ];
    }

    Log("chaddr: $old_address -> $new_address");

    # sanity check
    unless ($old_address && $new_address) {
	croak("chaddr: invalid arguments");
    }
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use IO::Adapter;
    use FML::Credential;
    use FML::Log qw(Log LogWarn LogError);

    for my $map ($member_map, $recipient_map) {
	my $cred = new FML::Credential;

	# the current member/recipient file must have $old_address
	# but should not contain $new_address.
	if ($cred->has_address_in_map($map, $old_address)) {
	    unless ($cred->has_address_in_map($map, $new_address)) {
		# remove the old address.
		{
		    my $obj = new IO::Adapter $map;
		    $obj->touch();

		    $obj->open();
		    $obj->delete( $old_address );
		    unless ($obj->error()) {
			Log("delete $old_address from map=$map");
		    }
		    else {
			croak("fail to delete $old_address to map=$map");
		    }
		    $obj->close();
		}

		# restart map to add the new address.
		# XXX we need to restart or rewrind map.
		{
		    my $obj = new IO::Adapter $map;
		    $obj->open();
		    $obj->add( $new_address );
		    unless ($obj->error()) {
			Log("add $new_address to map=$map");
		    }
		    else {
			croak("fail to add $new_address to map=$map");
		    }
		    $obj->close();
		}
	    }
	    else {
		$self->error_set("$new_address is already member (map=$map)");
		return undef;
	    }
	}
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::chaddr appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
