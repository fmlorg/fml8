#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.20 2003/11/23 03:54:45 fukachan Exp $
#

package FML::Command::Admin::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::Admin::chaddr - change the subscribed address

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change address from old one to new one.

=head1 METHODS

=head2 process($curproc, $command_args)

change address from old one to new one.

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


# Descriptions: change address from old one to new one.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $options = $command_args->{ options };

    # XXX We should always add/rewrite only $primary_*_map maps via 
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous 
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps. 
    my $member_map    = $config->{ 'primary_member_map'    };
    my $recipient_map = $config->{ 'primary_recipient_map' };

    my $old_address = '';
    my $new_address = '';
    if (defined $command_args->{ command_data }) {
	my $x = $command_args->{ command_data };
	($old_address, $new_address) = split(/\s+/, $x);
    }
    else {
	$old_address = $options->[ 0 ];
	$new_address = $options->[ 1 ];
    }

    $curproc->log("chaddr: $old_address -> $new_address");

    # XXX-TODO: validate $old_address and $new_address syntax.
    # sanity check
    unless ($old_address && $new_address) {
	croak("chaddr: invalid arguments");
    }
    croak("\$member_map not specified")    unless $member_map;
    croak("\$recipient_map not specified") unless $recipient_map;

    # uc_args = FML::User::Control specific parameters
    my (@maps) = ($member_map, $recipient_map);
    my $uc_args = {
	old_address => $old_address,
	new_address => $new_address,
	maplist     => \@maps,
    };
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->user_chaddr($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::chaddr first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
