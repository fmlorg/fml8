#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delmoderator.pm,v 1.7 2003/01/27 04:40:21 fukachan Exp $
#

package FML::Command::Admin::delmoderator;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::delmoderator - remove the specified moderator

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the specified moderator.

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


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: remove the specified moderator
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();

    # target maps
    my $member_maps    = $config->get_as_array_ref('moderator_member_maps');
    my $recipient_maps = $config->get_as_array_ref('moderator_recipient_maps');
    my $options        = $command_args->{ options };
    my $address        = $command_args->{ command_data } || $options->[ 0 ];

    # fundamental check
    croak("address not undefined")        unless defined $address;
    croak("address not specified")        unless $address;
    croak("member_maps not undefined")    unless defined $member_maps;
    croak("member_maps not specified")    unless $member_maps;
    croak("recipient_maps not undefined") unless defined $recipient_maps;
    croak("recipient_maps not specified") unless $recipient_maps;

    # maplist
    my $maplist = [];
    push(@$maplist, @$member_maps)    if @$member_maps;
    push(@$maplist, @$recipient_maps) if @$recipient_maps;

    # FML::Command::UserControl specific parameters
    my $uc_args = {
	address => $address,
	maplist => $maplist,
    };
    my $r = '';

    eval q{
	use FML::Command::UserControl;
	my $obj = new FML::Command::UserControl;
	$obj->userdel($curproc, $command_args, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu to remove the moderator
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $r = '';

    eval q{
	use FML::CGI::Admin::User;
	my $obj = new FML::CGI::Admin::User;
	$obj->cgi_menu($curproc, $args, $command_args);
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

FML::Command::Admin::delmoderator first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
