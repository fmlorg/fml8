#-*- perl -*-
#
#  Copyright (C) 2002,2003 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: digest.pm,v 1.13 2003/11/23 03:54:45 fukachan Exp $
#

package FML::Command::Admin::digest;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);


#
# XXX-TODO: clean up digest command more.
#


=head1 NAME

FML::Command::Admin::digest - toggle digest mode to off/on.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change digest mode for the specified address to off/on.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor.
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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: toggle delivery mode between real time and digest.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map,$digest_recipient_maps
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $options = $command_args->{ options } || [];

    # XXX We should always add/rewrite only $primary_*_map maps via 
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous 
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps. 
    my $recipient_map         = $config->{ primary_recipient_map };
    my $recipient_maps        = $config->get_as_array_ref('recipient_maps');
    my $digest_recipient_map  = $config->{ primary_digest_recipient_map };
    my $digest_recipient_maps =
	$config->get_as_array_ref('digest_recipient_maps');

    # XXX-TODO: validate $address ?
    my $address = $command_args->{ command_data } || $options->[ 0 ] || undef;
    my $mode    = $options->[ 1 ] || '';

    # fundamental check
    croak("address not defined")     unless defined $address;
    croak("address not specified")   unless $address;
    croak("primary_recipient_map not defined") unless defined $recipient_map;
    croak("recipient_maps not defined") unless defined $recipient_maps;
    croak("digest_recipient_map not defined")
	unless defined $digest_recipient_map;
    croak("digest_recipient_maps not definde")
	unless defined $digest_recipient_maps;

    my $digest_args = {
	address                      => $address,
	mode                         => $mode,
	primary_recipient_map        => $recipient_map,
	recipient_maps               => $recipient_maps,
	primary_digest_recipient_map => $digest_recipient_map,
	digest_recipient_maps        => $digest_recipient_maps,
    };

    if ($mode) {
	$mode =~ tr/A-Z/a-z/;

	if ($mode eq "on") {
	    $self->_digest_on($curproc, $command_args, $digest_args);
	}
	elsif ($mode eq "off") {
	    $self->_digest_off($curproc, $command_args, $digest_args);
	}
	else {
	    croak("unknown mode: mode is off or on");
	}
    }
    else {
	croak("specify mode: off or on");
    }
}


# Descriptions: change delivery mode to real time.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($dargs)
# Side Effects: update $recipient_map
# Return Value: none
sub _digest_on
{
    my ($self, $curproc, $command_args, $dargs) = @_;
    my $address               = $dargs->{ address };
    my $recipient_map         = $dargs->{ primary_recipient_map };
    my $digest_recipient_map  = $dargs->{ primary_digest_recipient_map };

    # move $address from normal $recipient_map to $digest_recipient_map
    my $uc_normal_args = {
	address => $address,
	maplist => [ $recipient_map ],
    };

    my $uc_digest_args = {
	address => $address,
	maplist => [ $digest_recipient_map ],
    };

    $self->_userdel($curproc, $command_args, $uc_normal_args);
    $self->_useradd($curproc, $command_args, $uc_digest_args);
}


# Descriptions: change delivery mode to digest.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($dargs)
# Side Effects: update $recipient_map
# Return Value: none
sub _digest_off
{
    my ($self, $curproc, $command_args, $dargs) = @_;
    my $address               = $dargs->{ address };
    my $recipient_map         = $dargs->{ primary_recipient_map };
    my $digest_recipient_map  = $dargs->{ primary_digest_recipient_map };

    # move $address from normal $digest_recipient_maps to $prmary_recipient_map
    my $uc_normal_args = {
	address => $address,
	maplist => [ $recipient_map ],
    };

    my $uc_digest_args = {
	address => $address,
	maplist => [ $digest_recipient_map ],
    };

    $self->_userdel($curproc, $command_args, $uc_digest_args);
    $self->_useradd($curproc, $command_args, $uc_normal_args);
}


# Descriptions: add the specified user.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update address list(s).
# Return Value: none
sub _useradd
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->useradd($curproc, $command_args, $uc_args);
    };

    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: remove the specified user.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($uc_args)
# Side Effects: update address list(s).
# Return Value: none
sub _userdel
{
    my ($self, $curproc, $command_args, $uc_args) = @_;
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->userdel($curproc, $command_args, $uc_args);
    };

    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu.
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    #
    # XXX-TODO: NOT IMPLEMENTED.
    #
    return;

    eval q{
	use FML::CGI::User;
	my $obj = new FML::CGI::User;
	$obj->cgi_menu($curproc, $args, $command_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002,2003 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::on first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
