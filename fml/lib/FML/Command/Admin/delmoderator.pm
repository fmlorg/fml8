#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delmoderator.pm,v 1.21 2006/03/04 13:48:28 fukachan Exp $
#

package FML::Command::Admin::delmoderator;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::delmoderator - remove the specified moderator.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

remove the specified moderator.

=head1 METHODS

=head2 process($curproc, $command_context)

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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: verify the syntax command string.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub verify_syntax
{
    my ($self, $curproc, $command_context) = @_;

    use FML::Command::Syntax;
    push(@ISA, qw(FML::Command::Syntax));
    $self->check_syntax_address_handler($curproc, $command_context);
}


# Descriptions: remove the specified moderator.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $options = $command_context->get_options();
    my $address = $command_context->get_data() || $options->[ 0 ];

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    For example, $member_maps contains different classes.
    my $member_map    = $config->{ 'primary_moderator_member_map' };
    my $recipient_map = $config->{ 'primary_moderator_recipient_map' };

    # fundamental sanity check
    croak("address not undefined")       unless defined $address;
    croak("address not specified")       unless $address;
    croak("member_map not undefined")    unless defined $member_map;
    croak("member_map not specified")    unless $member_map;
    croak("recipient_map not undefined") unless defined $recipient_map;
    croak("recipient_map not specified") unless $recipient_map;

    # $uc_args  = FML::User::Control specific parameters
    my $maplist = [ $member_map, $recipient_map ];
    my $uc_args = {
	address => $address,
	maplist => $maplist,
    };
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->user_del($curproc, $command_context, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: show cgi menu to remove the specified moderator.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    eval q{
	use FML::CGI::User;
	my $obj = new FML::CGI::User;
	$obj->cgi_menu($curproc, $command_context);
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

Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::delmoderator first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
