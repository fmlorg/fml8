#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: UserControl.pm,v 1.5 2002/04/10 09:57:22 fukachan Exp $
#

package FML::Command::UserControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;
use FML::Credential;
use FML::Log qw(Log LogWarn LogError);
use IO::Adapter;


=head1 NAME

FML::Command::UserControl - utility functions to send back file(s)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

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


# Descriptions: add user
#    Arguments: OBJ($self)
#               HASH_REF($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update maps
# Return Value: none
sub useradd
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $address = $uc_args->{ address };
    my $maplist = $uc_args->{ maplist };

    for my $map (@$maplist) {
	my $cred = new FML::Credential;
	unless ($cred->has_address_in_map($map, $address)) {
	    my $obj = new IO::Adapter $map;
	    $obj->touch(); # create a new map entry (e.g. file) if needed.
	    $obj->add( $address );
	    unless ($obj->error()) {
		Log("add $address to map=$map");
	    }
	    else {
		croak("fail to add $address to map=$map");
	    }
	}
	else {
	    croak( "$address is already member (map=$map)" );
	    return undef;
	}
    }
}


# Descriptions: remove user
#    Arguments: OBJ($self)
#               HASH_REF($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update maps
# Return Value: none
sub userdel
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $address = $uc_args->{ address };
    my $maplist = $uc_args->{ maplist };

    for my $map (@$maplist) {
	my $cred = new FML::Credential;
	if ($cred->has_address_in_map($map, $address)) {
	    my $obj = new IO::Adapter $map;
	    $obj->delete( $address );
	    unless ($obj->error()) {
		Log("removed $address from map=$map");
	    }
	    else {
		croak("fail to remove $address from map=$map");
	    }
	}
	else {
	    LogWarn("no such user in map=$map");
	}
    }
}


# Descriptions: show list
#    Arguments: OBJ($self)
#               HASH_REF($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: none
# Return Value: none
sub userlist
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $maplist = $uc_args->{ maplist };
    my $wh      = $uc_args->{ wh };

    for my $map (@$maplist) {
	my $obj = new IO::Adapter $map;

	if (defined $obj) {
	    my $x = '';
	    $obj->open || croak("cannot open $map");
	    while ($x = $obj->get_next_key()) { print $wh $x, "\n"; }
	    $obj->close;
	}
	else {
	    LogWarn("canot open $map");
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

FML::Command::UserControl appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
