#-*- perl -*-
#
#  Copyright (C) 2002,2003 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: on.pm,v 1.13 2003/11/23 03:54:46 fukachan Exp $
#

package FML::Command::Admin::on;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::on - change delivery mode from digest to real time

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change delivery mode from digest to real time.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor
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


# Descriptions: change delivery mode from digest to real time.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $options = $command_args->{ options };
    my $address = $command_args->{ command_data } || $options->[ 0 ];

    # XXX We should always add/rewrite only $primary_*_map maps via 
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous 
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps. 
    my $recipient_map = $config->{ primary_recipient_map };

    # fundamental check
    croak("address not defined")           unless defined $address;
    croak("\$recipient_map not defined")   unless defined $recipient_map;
    croak("address not specified")         unless $address;
    croak("\$recipient_map not specified") unless $recipient_map;

    # FML::User::Control specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ $recipient_map ],
    };
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


# Descriptions: show cgi menu for on
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: update $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

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
