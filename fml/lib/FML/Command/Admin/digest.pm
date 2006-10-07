#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: digest.pm,v 1.27 2006/03/05 08:08:36 fukachan Exp $
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

=head2 new()

constructor.

=head2 need_lock()

need lock or not.

=head2 lock_channel()

return lock channel name.

=head2 verify_syntax($curproc, $command_context)

provide command specific syntax checker.

=head2 process($curproc, $command_context)

main command specific routine.

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


# Descriptions: toggle delivery mode between real time and digest.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map,$digest_recipient_maps
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
    # XXX    for example, member_maps contains different classes.
    my $recipient_map         = $config->{ primary_recipient_map };
    my $recipient_maps        = $config->get_as_array_ref('recipient_maps');
    my $digest_recipient_map  = $config->{ primary_digest_recipient_map };
    my $digest_recipient_maps =
	$config->get_as_array_ref('digest_recipient_maps');

    my $address = $command_context->get_data() || $options->[ 0 ] || undef;
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

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	$curproc->logerror("digest: unsafe address <$address>");
	croak("unsafe address");
    }

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
	    $self->_digest_on($curproc, $command_context, $digest_args);
	}
	elsif ($mode eq "off") {
	    $self->_digest_off($curproc, $command_context, $digest_args);
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
#               OBJ($curproc) OBJ($command_context) HASH_REF($dargs)
# Side Effects: update $recipient_map
# Return Value: none
sub _digest_on
{
    my ($self, $curproc, $command_context, $dargs) = @_;
    my $config               = $curproc->config();
    my $cred                 = $curproc->credential();
    my $address              = $dargs->{ address };
    my $recipient_map        = $dargs->{ primary_recipient_map };
    my $digest_recipient_map = $dargs->{ primary_digest_recipient_map };

    # move $address from normal $recipient_map to $digest_recipient_map
    my $uc_normal_args = {
	address => $address,
	maplist => [ $recipient_map ],
    };

    my $uc_digest_args = {
	address => $address,
	maplist => [ $digest_recipient_map ],
    };

    my $msg_args = {
	_arg_address => $address,
    };

    # 1. remove address from $recipient_map (normal delivery recipients).
    #    we should remove address if $recipient_map conatins it.
    if ($cred->has_address_in_map($recipient_map, $config, $address)) {
	$self->_user_del($curproc, $command_context, $uc_normal_args);
    }
    else {
	my $r = "no such recipient";
	$curproc->reply_message_nl('error.no_such_recipient', $r, $msg_args);
	$curproc->logerror($r);
	croak($r);
    }

    # 2. add address into $digest_recipient_map
    if ($cred->has_address_in_map($digest_recipient_map, $config, $address)) {
	my $r = "already digest recipient";
	$curproc->reply_message_nl('error.already_digest_recipient',
				   $r,
				   $msg_args);
	$curproc->logerror($r);
	croak($r);
    }
    else {
	$self->_user_add($curproc, $command_context, $uc_digest_args);
    }

    # XXX-TODO: need transaction ?
}


# Descriptions: change delivery mode to digest.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($dargs)
# Side Effects: update $recipient_map
# Return Value: none
sub _digest_off
{
    my ($self, $curproc, $command_context, $dargs) = @_;
    my $config               = $curproc->config();
    my $cred                 = $curproc->credential();
    my $address              = $dargs->{ address };
    my $recipient_map        = $dargs->{ primary_recipient_map };
    my $digest_recipient_map = $dargs->{ primary_digest_recipient_map };

    # move $address from normal $digest_recipient_maps to $prmary_recipient_map
    my $uc_normal_args = {
	address => $address,
	maplist => [ $recipient_map ],
    };

    my $uc_digest_args = {
	address => $address,
	maplist => [ $digest_recipient_map ],
    };

    my $msg_args = {
	_arg_address => $address,
    };

    # 1. remove address from digest_recipient_map.
    #    we should remove address if $digest_recipient_map contains it.
    if ($cred->has_address_in_map($digest_recipient_map, $config, $address)) {
	$self->_user_del($curproc, $command_context, $uc_digest_args);
    }
    else {
	my $r = "no such digest recipient";
	$curproc->reply_message_nl('error.no_such_digest_recipient',
				   $r,
				   $msg_args);
	$curproc->logerror($r);
	croak($r);
    }

    # 2. add address into normal recipient map.
    if ($cred->has_address_in_map($recipient_map, $config, $address)) {
	my $r = "already recipient";
	$curproc->reply_message_nl('error.already_recipient',
				   $r,
				   $msg_args);
	$curproc->logerror($r);
	croak($r);
    }
    else {
	$self->_user_add($curproc, $command_context, $uc_normal_args);
    }

    # XXX-TODO: need transaction ?
}


# Descriptions: add the specified user.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($uc_args)
# Side Effects: update address list(s).
# Return Value: none
sub _user_add
{
    my ($self, $curproc, $command_context, $uc_args) = @_;
    my $r = '';

    eval q{
	use FML::User::Control;
	my $obj = new FML::User::Control;
	$obj->user_add($curproc, $command_context, $uc_args);
    };

    if ($r = $@) {
	croak($r);
    }
}


# Descriptions: remove the specified user.
#    Arguments: OBJ($self)
#               OBJ($curproc) OBJ($command_context) HASH_REF($uc_args)
# Side Effects: update address list(s).
# Return Value: none
sub _user_del
{
    my ($self, $curproc, $command_context, $uc_args) = @_;
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


# Descriptions: show cgi menu.
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: update $recipient_map
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $r = '';

    #
    # XXX-TODO: NOT IMPLEMENTED.
    #
    return;

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

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::on first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
