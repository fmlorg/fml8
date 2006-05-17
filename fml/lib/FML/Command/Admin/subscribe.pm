#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: subscribe.pm,v 1.38 2006/05/16 14:36:30 fukachan Exp $
#

package FML::Command::Admin::subscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::Admin::subscribe - subscribe a new member.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

subscribe a new address.

=head1 METHODS

=head2 process($curproc, $command_context)

subscribe a new user.

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


# Descriptions: lock channel
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


# Descriptions: subscribe a new user.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    my $config  = $curproc->config();
    my $options = $command_context->get_options() || [];
    my $address = $command_context->get_data() || $options->[ 0 ];

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps.
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };

    # fundamental check
    croak("address is not defined")           unless defined $address;
    croak("address is not specified")         unless $address;
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    # check if member/recipient total exceeds the limit.
    if ($self->_is_member_total_exceed_limit($curproc, $command_context)) {
	my $key            = "limit.exceed_user_total";
	my $default_msg    = "exceed the user total limit.";
	my $maintainer     = $config->{ maintainer };
	my $recipient_list = [ $maintainer, $address ];
	my $rm_args        = { recipient => $recipient_list };
	$curproc->reply_message_nl($key, $default_msg, $rm_args);
	croak("total number of subscribers exceeds the limit.");
    }

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	$curproc->logerror("subscribe: unsafe address <$address>");
	croak("unsafe address");
    }

    # FML::User::Control specific parameters
    my $uc_args = {
	address => $address,
	maplist => [ $recipient_map, $member_map ],
    };
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->user_add($curproc, $command_context, $uc_args);
    };
    if ($r = $@) {
	croak($r);
    }

    # send back a file.
    if ($curproc->is_cgi_process() || $curproc->is_under_mta_process()) {
	use FML::Command::SendFile;
	push(@ISA, qw(FML::Command::SendFile));
	$command_context->{ _recipient } = $address;
	$self->send_user_xxx_message($curproc, $command_context, "welcome");
	delete $command_context->{ _recipient };
    }
}


# Descriptions: show cgi menu for subscribe command.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $member_map $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    # XXX-TODO: $command_context checked ?
    eval q{
	use FML::CGI::User;
	my $obj = new FML::CGI::User;
	$obj->cgi_menu($curproc, $command_context);
    };
    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: check the total of members/recipients exceeds the limit.
#               return 1 if exceeded.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM
sub _is_member_total_exceed_limit
{
    my ($self, $curproc, $command_context) = @_;
    my $match = 0;

  TYPE:
    for my $type (qw(recipient member)) {
	my $r = $self->_check_total_limit($curproc, $command_context, $type);
	$match = $r;
	last TYPE if $r;
    }

    return $match;
}


# Descriptions: check the number of users in ${map_name}_maps 
#               exceeds the limit or not.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context) STR($map_name)
# Side Effects: none
# Return Value: NUM
sub _check_total_limit
{
    my ($self, $curproc, $command_context, $map_name) = @_;

    # 1. count up the total number of recipients.
    use FML::User::Control;
    my $control    = new FML::User::Control;
    my $var_maps   = sprintf("%s_maps", $map_name);
    my $config     = $curproc->config();
    my $maplist    = $config->get_as_array_ref($var_maps); 
    my $user_total = $control->get_user_total($curproc, $maplist);

    # 2. compare. return 1 if the total exceeds the limit.
    my $var_yesno_name = sprintf("use_%s_total_limit", $map_name);
    if ($config->yes($var_yesno_name)) {
	my $var_limit_name = sprintf("%s_total_limit", $map_name);
	my $user_limit = $config->{ $var_limit_name } || 0;
	if ($user_limit) {
	    return ($user_total > $user_limit) ? 1 : 0;
	}
    }

    return 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::subscribe first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
