#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.28 2006/03/04 13:48:28 fukachan Exp $
#

package FML::Command::Admin::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::chaddr - change the subscribed address.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change address from old one to new one.

=head1 METHODS

=head2 process($curproc, $command_context)

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
    my $comname    = $command_context->get_cooked_command()    || '';
    my $comsubname = $command_context->get_cooked_subcommand() || '';
    my $options    = $command_context->get_options()    || [];
    my @test       = ($comname);
    my $command    = $options->[ 0 ] || '';
    my $oldaddr    = $options->[ 1 ] || '';
    my $newaddr    = $options->[ 2 ] || '';
    push(@test, $command);

    my $ok = 0;

    use FML::Restriction::Base;
    my $dispatch = new FML::Restriction::Base;
    if ($dispatch->regexp_match('address', $oldaddr)) {
	$ok++;
    }
    else {
	$curproc->logerror("insecure address: <$oldaddr>");
	return 0;
    }

    if ($dispatch->regexp_match('address', $newaddr)) {
	$ok++;
    }
    else {
	$curproc->logerror("insecure address: <$newaddr>");
	return 0;
    }

    use FML::Command;
    $dispatch = new FML::Command;
    if ($dispatch->safe_regexp_match($curproc, $command_context, \@test)) {
	$ok++;
    }

    return( $ok == 3 ? 1 : 0 );
}


# Descriptions: change address from old one to new one.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $options = $command_context->get_options() || [];

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, $member_maps contains different classes.
    my $member_map    = $config->{ 'primary_member_map'    };
    my $recipient_map = $config->{ 'primary_recipient_map' };

    my $old_address  = '';
    my $new_address  = '';
    my $command_data = $command_context->get_data() || '';
    if ($command_data) {
	($old_address, $new_address) = split(/\s+/, $command_data);
    }
    else {
	$old_address = $options->[ 0 ];
	$new_address = $options->[ 1 ];
    }

    $curproc->log("chaddr: $old_address -> $new_address");

    # sanity check
    unless ($old_address && $new_address) {
	croak("chaddr: invalid arguments");
    }
    croak("\$member_map not specified")    unless $member_map;
    croak("\$recipient_map not specified") unless $recipient_map;

    # check syntax of old or new addresses.
    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $old_address)) {
	croak("chaddr: unsafe old address: $old_address");
    }
    unless ($safe->regexp_match('address', $new_address)) {
	croak("chaddr: unsafe new address: $new_address");
    }

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
	$obj->user_chaddr($curproc, $command_context, $uc_args);
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

FML::Command::Admin::chaddr first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
