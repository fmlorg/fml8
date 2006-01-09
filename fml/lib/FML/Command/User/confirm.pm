#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: confirm.pm,v 1.37 2006/01/08 03:06:59 fukachan Exp $
#

package FML::Command::User::confirm;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::User::confirm - allow action after confirmation.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

execute the actual corresponding process if the confirmation succeeds.

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


# Descriptions: addresses to inform a message copy to.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: ARREY_REF
sub notice_cc_recipient
{
   my ($self, $curproc, $command_args) = @_;
   my $config     = $curproc->config();
   my $maintainer = $config->{ maintainer };

   return [ $maintainer ];
}


# Descriptions: execute the actual process if this confirmation succeeds.
#               run _switch_command() for real process.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();
    my ($class, $id);

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps.
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $expire_limit  = $config->{ confirm_expire_limit } || 14*24*3600;
    my $command       = $command_args->{ command };


    # XXX-TODO: sanity


    # get class and id from buffer, for example,
    # "confirm subscribe 813f42fa2aa84bbba500ed3d2781dea6"
    # XXX $keyword may not start at the begining of this line.
    # XXX For example, "confirm", "> confirm" and "xxx> confirm ..."
    # XXX-TODO: we should move this check to FML::Command::__SOME_WHERE__ ?
    if ($command =~ /$keyword\s+(\w+)\s+([\w\d]+)/) {
	($class, $id) = ($1, $2);
    }

    # XXX-TODO: ($class, $id) sanity check ?
    # XXX-TODO: if ($class && $id) { ... }
    use FML::Confirm;
    my $confirm = new FML::Confirm $curproc, {
	keyword   => $keyword,
	cache_dir => $cache_dir,
	class     => $class,
	buffer    => $command,
    };

    my $found = '';
    if ($found = $confirm->find($id)) { # if request is found
	unless ($confirm->is_expired($id, $expire_limit)) {
	    $self->_switch_process($confirm,
				   $class,
				   $id,
				   $curproc,
				   $command_args);
	}
	else { # if requset is expired
	    $curproc->reply_message_nl('error.expired', "request expired");
	    $curproc->logerror("request expired");
	    croak("request is expired");
	}
    }
    # request corresponding to thie confirmation reply is not found
    else {
	$curproc->reply_message_nl('error.no_such_confirmation',
				   "no such confirmatoin request id=$id",
				   { _arg_id => $id });
	$curproc->logerror("no such confirmation request id=$id");
	croak("no such confirmation request id=$id");
    }
}


# Descriptions: load module for the actual process and
#               switch this process to it.
#               We support only {subscribe,unsubscribe,chaddr} now.
#    Arguments: OBJ($self) OBJ($confirm) STR($class) STR($id)
#               OBJ($curproc) HASH_REF($command_args)
# Side Effects: module loaded
# Return Value: none
sub _switch_process
{
    my ($self, $confirm, $class, $id, $curproc, $command_args) = @_;
    my $config  = $curproc->config();
    my $command = $class;
    my $varname = "${command}_command_operation_mode";
    my $mode    = $config->{ $varname } || 'confirmation';
    my $address = $confirm->get_address($id);
    my $request = $confirm->get_request($id);

    # pass confirmation id to the command layer.
    $command_args->{ _confirm_id }      = $id;
    $command_args->{ _confirm_address } = $address;
    $command_args->{ _confirm_request } = $request;

    # 1. XXX_command_operation_mode == automatic
    #    fml8 do subscription et.al. automatically.
    if ($mode eq 'automatic') {
	$self->_switch_command($class, $address, $curproc, $command_args);
    }
    # 2. XXX_command_operation_mode == manual
    #    notify "the request is confirmed" to $maintainer,
    #    who do actual subscription et.al.
    elsif ($mode eq 'manual') {
	$self->_forward_request($class, $address, $curproc, $command_args);
    }
    else {
	croak("unknown operation mode");
    }

    # clean up.
    delete $command_args->{ _confirm_id };
    delete $command_args->{ _confirm_address };
    delete $command_args->{ _confirm_request };
}


# Descriptions: load module for the actual process and
#               switch this process to it.
#               We support only {subscribe,unsubscribe,chaddr} now.
#    Arguments: OBJ($self) STR($class) STR($address)
#               OBJ($curproc) HASH_REF($command_args)
# Side Effects: module loaded
# Return Value: none
sub _switch_command
{
    my ($self, $class, $address, $curproc, $command_args) = @_;

    # lower case
    $class =~ tr/A-Z/a-z/;

    use FML::Command;
    my $obj = new FML::Command;

    # XXX-TODO: command names which need confirmation are hard-coded.
    # XXX-TODO: define available command list in $config.
    if ($class eq 'subscribe'   ||
	$class eq 'unsubscribe' ||
	$class eq 'chaddr' ||
	$class eq 'on'     ||
	$class eq 'off'    ||
	$class eq 'moderate') {
	$command_args->{ command_data } = $address;
	$command_args->{ command_mode } = 'Admin';
	$command_args->{ override_need_no_lock } = 1; # already locked
	$obj->$class($curproc, $command_args);
    }
    else {
	$curproc->logerror("no such confirmation rule for '$class' command");
	$curproc->reply_message_nl('error.no_such_confirmation_for_command',
				   "no such confirmation for command $class",
				   { _arg_command => $class });
	croak("no such rule");
    }

    # XXX-TODO: send back welcome file.
    # XXX-TODO: temporary solution, please clean up in near future!
    if ($class eq 'subscribe') {
	use File::Spec;
	use FML::Command::SendFile;
	push(@ISA, qw(FML::Command::SendFile));

	my $config      = $curproc->config();
	my $ml_home_dir = $config->{ ml_home_dir };
	my $file        = File::Spec->catfile($ml_home_dir, "welcome");
	$config->set( 'welcome_file', $file );

	if (-f $file) {
	    $self->send_user_xxx_message($curproc, $command_args, "welcome");
	}
    }

    if ($class eq 'unsubscribe') {
	$curproc->command_context_set_normal_stop();
	$curproc->log("need no more command processing.");
    }
}


# Descriptions: load module for the actual process and
#               switch this process to it.
#               We support only {subscribe,unsubscribe,chaddr} now.
#    Arguments: OBJ($self) STR($class) STR($address)
#               OBJ($curproc) HASH_REF($command_args)
# Side Effects: module loaded
# Return Value: none
sub _forward_request
{
    my ($self, $class, $address, $curproc, $command_args) = @_;
    my $msg        = $curproc->incoming_message();
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };
    my $action     = "?";
    my $command    = $class;
    my $request    = $command_args->{ _confirm_request };
    my (@address)  = split(/\s+/, $address);
    my $user_args  = { recipient => \@address };
    my $rm_args    = {
	recipient    => $maintainer,
	_arg_address => $address,
	_arg_command => $command,
	_arg_request => $request,
    };
    my $default    = "send back the following confirmation.";
    my $default2   = "?";
    my $key1       = 'command.forward_request_to_admin';
    my $key2       = 'command.receive_confirmed_request';

    # 2.1 notify "forwarded request to maintainer(s)." to sender(s).
    $curproc->reply_message_nl($key1, "", $user_args);

    # 2.2 notify request to maintainer(s).
    $curproc->reply_message_nl($key2, $default2, $rm_args);
    $curproc->reply_message($msg, $rm_args);
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

FML::Command::User::confirm first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
