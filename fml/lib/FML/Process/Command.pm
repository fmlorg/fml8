#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Command.pm,v 1.52 2002/04/26 10:29:13 fukachan Exp $
#

package FML::Process::Command;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Command -- command dispacher.

=head1 SYNOPSIS

   use FML::Process::Command;
   ...

See L<FML::Process::Flow> for details of fml process flow.

=head1 DESCRIPTION

C<FML::Process::Command> is a command wrapper and top level
dispatcher for commands.
It kicks off corresponding

   FML::Command->$command($curproc, $command_args)

for the given C<$command>.

=head1 METHODS

=head2 C<new($args)>

make fml process object, which inherits C<FML::Process::Kernel>.

=cut


# Descriptions: standard constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: inherit FML::Process::Kernel
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare($args)>

forward the request to SUPER CLASS.

=cut

# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($self, $args) = @_;
    my $config = $self->{ config };

    my $eval = $config->get_hook( 'command_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $self->SUPER::prepare($args);

    $eval = $config->get_hook( 'command_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<verify_request($args)>

verify the sender is a valid member or not.

=cut


# Descriptions: verify the sender of this process is an ML member.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'command_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->verify_sender_credential();

    $eval = $config->get_hook( 'command_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<run($args)>

dispatcher to run correspondig C<FML::Command::command> for
C<command>. Standard style follows:

    lock
    execute FML::Command::command
    unlock

XXX Each command determines need of lock or not.

=cut


# Descriptions: call _evaluate_command_lines()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $pcb = $curproc->{ pcb };

    if ($curproc->permit_command($args)) {
	$curproc->_evaluate_command_lines($args);
    }
    else {
	my $reason = $pcb->get("check_restrictions", "deny_reason");
	if (defined($reason) && ($reason eq 'reject_system_accounts')) {
	    $curproc->reply_message_nl("error.system_accounts",
				       "deny request from system accounts");
	}
	else {
	    $curproc->reply_message_nl("error.not_member",
				       "deny request from a not member");
	}

	# append the incoming message as the reference
	my $msg  = $curproc->{ incoming_message }->{ message };
	$curproc->reply_message( $msg );

	unless (defined $reason) { $reason = 'unknown';}
	Log("deny command. reason=$reason");
    }
}


=head2 help()

show help.

=cut


# Descriptions: show help
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
print <<"_EOF_";

Usage: $0 \$ml_home_prefix/\$ml_name [options]

   For example, process command of elena ML
   $0 /var/spool/ml/elena

_EOF_
}


=head2 C<finish($args)>

    $curproc->inform_reply_messages();

=cut


# Descriptions: finalize command process.
#               reply messages, command results et. al.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: queue manipulation
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'command_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'command_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: check message of the current process
#               whether it contais keyword e.g. "confirm".
#    Arguments: OBJ($curproc) ARRAY_REF($ra_data)
# Side Effects: none
# Return Value: ARRAY
sub _pre_scan
{
    my ($curproc, $ra_data) = @_;

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    my $data  = $check->find_special_keyword($curproc, $ra_data);
    return ($data->{ confirm_keyword }, $data->{ admin_keyword });
}


# Descriptions: check command (specified in $opts) content:
#               syntax check, permission of command use et. al.
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($opts)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_valid_command
{
    my ($curproc, $args, $level, $opts) = @_;
    my $config  = $curproc->{ config };
    my $cred    = $curproc->{ credential }; # user credential
    my $prompt  = $config->{ command_prompt } || '>>>';
    my $comname = $opts->{ comname };
    my $command = $opts->{ command };

    # use of this command is allowed in FML::Config or not ?
    unless ($config->has_attribute("commands_for_$level", $comname)) {
	if ($level eq 'admin' || $level eq 'user') {
	    Log("commands_for_$level has no $comname");
	    $curproc->reply_message("\n$prompt $command");
	    $curproc->reply_message_nl('command.not_command',
				       "not command, ignored.");
	}
	return 0;
    }

    return 1; # o.k. accpet this command.
}


sub _is_valid_syntax
{
    my ($curproc, $args, $status, $command) = @_;
    my $config = $curproc->{ config };
    my $prompt = $config->{ command_prompt } || '>>>';
    my $level  = $status->{ level };

    Log("_is_valid_syntax($command) level=$level");

    # simple command syntax check
    use FML::Restriction::Command;
    if (FML::Restriction::Command::is_secure_command_string( $command )) {
	return 1;
    }
    else {
	if ($level eq 'admin') {
	    LogError("insecure command: $command");
	    $curproc->reply_message("\n$prompt $command");
	    $curproc->reply_message_nl('command.insecure',
				       "insecure, so ignored.");
	}
	return 0;
    }
}


# Descriptions: parse command buffer to make
#               argument vector after command name
#    Arguments: STR($command) STR($comname)
# Side Effects: none
# Return Value: ARRAY_REF
sub _parse_command_arguments
{
    my ($command, $comname) = @_;

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    $check->parse_command_arguments($command, $comname);
}


# Descriptions: return command name ( ^\S+ in $command ).
#               remove the prepending strings such as \s, #, ...
#    Arguments: STR($command)
# Side Effects: none
# Return Value: ARRAY
sub _get_command_name
{
    my ($command) = @_;

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    $check->parse_command_buffer($command)
}


# Descriptions: authenticate the currrent process sender as an admin
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _auth_admin
{
    my ($curproc, $args, $optargs) = @_;
    my $is_auth = 0;
    my $obj     = undef;

    eval q{
	use FML::Command::Auth;
	$obj = new FML::Command::Auth;
    };
    unless ($@) {
	my $config = $curproc->{ config };
	my $rules  = $config->get_as_array_ref('admin_command_restrictions');
	for my $rule (@$rules) {
	    if ($rule eq 'reject') {
		return 0;
	    }

	    $is_auth = $obj->$rule($curproc, $args, $optargs);
	    if ($is_auth) {
		return $is_auth;
	    }
	    else {
		Log("admin: $rule fail");
	    }
	}
    }
    else {
	return 0;
    }

    # deny transition to admin mode by default
    return 0;
}


sub _get_command_mode
{
    my ($curproc, $args, $status, $command_info) = @_;
    my $config     = $curproc->{ config };
    my $command    = $command_info->{ command };
    my $comname    = $command_info->{ comname };
    my $comsubname = $command_info->{ comsubname };
    my $is_auth    = $status->{ is_auth };
    my $is_admin   = $status->{ is_admin };
    my $is_member  = $status->{ is_member };
    my $confirm_id = $status->{ confirm_id };

    # special traps are needed for "confirm" and "admin" commands.
    my $confirm_prefix = $config->{ confirm_command_prefix };
    my $admin_prefix   = $config->{ privileged_command_prefix };


    # Case: "confirm" command.
    #        It is exceptional strangers can use.
    #        validate general command except for confirmation
    #        if $confirm_id is 1, this message must be confirmation reply.
    if ($command =~ /$confirm_prefix\s+/ && $confirm_id) {
	# XXX $command may be "> confirm chaddr ...".
	$comname = $confirm_prefix;          # comname = confirm
	$command =~ s/^.*$comname/$comname/; # normalize $command
	my $opts    = { comname => $comname, command => $command };

	if ($curproc->_is_valid_command($args, "stranger", $opts)) {
	    $status->{ mode }  = 'user';
	    $status->{ level } = 'stranger';
	}
	else {
	    # no, we do not accept this command.
	    Log("invalid command: $command");
	    return '__NEXT__';
	}
    }
    # Case: "admin" command is exceptional. try priviledged mode.
    elsif ($comname =~ /$admin_prefix\s+/) {
	if ($is_auth) {
	    Log("admin auth already: $command");
	}
	else { # for the first time ?
	    my $sender  = $curproc->{'credential'}->{'sender'};
	    my $data    = $command;

	    $data =~ s/.*(password|pass)\s+//;
	    my $optargs = { address => $sender, password => $data };

	    # try auth by FML::Command::Auth;
	    $is_auth = $curproc->_auth_admin($args, $optargs);
	    Log("authenticated as an ML administrator") if $is_auth;
	}

	if ($is_admin && $is_auth) {
	    $comname = $comsubname;
	    $command =~ s/^.*$comname/admin $comname/;
	    my $opts    = { comname => $comname, command => $command };

	    my $xmode = 'privileged_user';
	    if ($curproc->_is_valid_command($args, $xmode, $opts)) {
		$status->{ mode }  = 'admin';
		$status->{ level } = 'admin';
	    }
	    else {
		# no, we do not accept this command.
		Log("invalid command(priv mode): $command");
		return '__NEXT__';
	    }
	}
	else {
	    LogError("privileged command from not an admin user");
	    LogError("command processing stop.");
	    return '__LAST__';
	}
    }
    # Case: use command (commands "a usual member" can use)
    else {
	if ($is_member) {
	    my $opts = { comname => $comname, command => $command };
	    if ($curproc->_is_valid_command($args, "user", $opts)) {
		$status->{ mode }  = 'user';
		$status->{ level } = 'user';
	    }
	    else {
		# no, we do not accept this command.
		Log("invalid command: $command");
		return '__NEXT__';
	    }
	}
	else {
	    my $opts = { comname => $comname, command => $command };
	    if ($curproc->_is_valid_command($args, "stranger", $opts)) {
		$status->{ mode }  = 'user';
		$status->{ level } = 'stranger';
	    }
	    else {
		if ($status->{ level } eq 'admin') {
		    LogError("command from not member.");
		    LogError("command processing stop.");
		    return '__LAST__';
		}
		else {
		    Log("(debug) ignore $command");
		    return '__NEXT__';
		}
	    }
	}
    }

    return $status->{ mode };
}


sub _allow_command()
{
    my ($curproc, $mode, $status, $command_info) = @_;
    my $level = $status->{ level };

    Log("(debug) mode=$mode level=$level");

    1;
}


sub __clean_up
{
    my ($buf) = @_;
    $buf =~ s/^\W+//;
    return $buf;
}


# Descriptions: scan message body and execute approviate command
#               with dynamic loading of command definition.
#               It resolves your customized command easily.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: loading FML::Command::command.
#               prepare messages to return.
# Return Value: none
sub _evaluate_command_lines
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    my $argv    = $curproc->command_line_argv();
    my $prompt  = $config->{ command_prompt } || '>>>';
    my $mode    = 'unknown';
    my $rbody   = $curproc->{ incoming_message }->{ body };
    my $msg     = $rbody->find_first_plaintext_message();

    # preliminary scanning for message to find "confirm" or "admin"
    my $command_lines = $msg->message_text_as_array_ref();
    my ($confirm_id, $admin_password) = $curproc->_pre_scan($command_lines);

    # [user credential check]
    #     is_admin: whether From: is a member of admin users.
    #      is_auth: authenticated or not by e.g. password
    my $cred      = $curproc->{ credential };
    my $is_member = $cred->is_member($curproc, $args);
    my $is_admin  = $cred->is_privileged_member($curproc, $args);
    my $is_auth   = 0;
    my $status    = {
	is_auth        => $is_auth,
	is_admin       => $is_admin,
	is_member      => $is_member,
	mode           => $mode,
	level          => 'unknown',
	confirm_id     => $confirm_id, 
	admin_password => $admin_password,
    };

    my $eval = $config->get_hook( 'command_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # firstly, prompt (for politeness :) to show processing ...
    $curproc->reply_message("result for your command requests follows:");

    # the main loop to analyze each command at each line.
    my ($comname, $comsubname, $comoptions, $cominfo, $fixed_command);
  COMMAND:
    for my $orig_command (@$command_lines) {
	next COMMAND if $orig_command =~ /^\s*$/; # ignore empty lines

	Log("(debug) input: $orig_command"); # log raw buffer

	# Example: if orig_command = "# help", comname = "help"
	$fixed_command = __clean_up($orig_command);
	($comname, $comsubname) = _get_command_name($fixed_command);
	$comoptions = _parse_command_arguments($fixed_command, $comname);
	$cominfo = {
	    command    => $fixed_command,
	    comname    => $comname,
	    comsubname => $comsubname,
	    comoptions => $comoptions,
	};
	$mode = $curproc->_get_command_mode($args, $status, $cominfo);

	# check if the further processing is allowed
	next COMMAND if $mode eq '__NEXT__';
	unless ($mode eq 'user' || $mode eq 'admin' || $mode eq 'special') {
	    LogError("command processing looks insane. stop.");
	    last COMMAND;
	}

	# check if this command is allowed in the current $mode ?
	unless ($curproc->_allow_command($mode, $status, $cominfo)) {
	    Log("(debug) ignore $fixed_command");
	    next COMMAND;
	}

	unless ($curproc->_is_valid_syntax($args, $status, $fixed_command)) {
	    Log("(debug) ignore $fixed_command");
	    next COMMAND;
	}

	Log("execute \"$fixed_command\"");

	# o.k. here we go to execute command
	use FML::Command;
	my $obj = new FML::Command;
	if (defined $obj) {
	    # arguments to pass off to each method
	    my $command_args = {
		command_mode => $mode,
		command      => $fixed_command,
		comname      => $comname,
		comsubname   => $comsubname,
		options      => $comoptions,
		ml_name      => $ml_name,
		argv         => $argv,
		args         => $args,
	    };

	    # rewrite prompt e.g. to hide the password
	    $obj->rewrite_prompt($curproc, $command_args, \$orig_command);

	    # reply buffer
	    $curproc->reply_message("\n$prompt $orig_command");
	    Log($orig_command);

	    # execute command ($comname method) under eval().
	    # XXX $obj = FML::Command object NOT FML::Command::$mode::$command
	    eval q{
		$obj->$comname($curproc, $command_args);
	    };
	    unless ($@) {
		$curproc->reply_message_nl('command.ok', "ok.");
	    }
	    else { # error trap
		my $reason = $@;
		Log($reason);

		$curproc->reply_message_nl('command.fail', "fail.");
		LogError("command ${comname} fail");

		if ($reason =~ /^(.*)\s+at\s+/) {
		    my $reason = $1;
		    Log($reason); # pick up reason
		}
	    }
	}
    } # END OF FOR LOOP: for my $orig_command (@body) { ... }

    $eval = $config->get_hook( 'command_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Command appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
