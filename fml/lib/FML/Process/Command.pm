#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Command.pm,v 1.93 2004/01/01 23:52:15 fukachan Exp $
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

=head2 new($args)

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


=head2 prepare($args)

adjust ml_* and load configuration files.
parse the incoming message.

=cut

# Descriptions: adjust ml_* and load configuration files.
#               parse the incomiung message.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'command_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    my $cf_list = $curproc->get_config_files_list();
    $curproc->load_config_files($cf_list);
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    if ($config->yes('use_command_mail_program')) {
	$curproc->parse_incoming_message();
    }
    else {
	$curproc->logerror("use of command_mail_program prohibited");
	exit(0);
    }

    $eval = $config->get_hook( 'command_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

verify the sender is a valid member or not.

=cut


# Descriptions: verify the sender of this process is an ML member.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: 1 or 0
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'command_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->verify_sender_credential();

    unless ($curproc->is_refused()) {
	$curproc->_check_filter();
    }

    $eval = $config->get_hook( 'command_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: filter
#    Arguments: OBJ($curproc)
# Side Effects: set flag to ignore this process if it should be filtered.
# Return Value: none
sub _check_filter
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    eval q{
	use FML::Filter;
	my $filter = new FML::Filter;
	my $r = $filter->command_mail_filter($curproc);

	# filter traps this message.
	if ($r = $filter->error()) {
	    if ($config->yes('use_command_mail_filter_reject_notice')) {
		my $msg_args = {
		    _arg_reason => $r,
		};

		$curproc->log("(debug) filter: inform rejection");
		$filter->command_mail_filter_reject_notice($curproc,$msg_args);
	    }
	    else {
		$curproc->log("filter: not inform rejection");
	    }

	    # we should stop this process ASAP.
	    $curproc->stop_this_process();
	    $curproc->log("rejected by filter due to $r");
	}
    };
    $curproc->log($@) if $@;
}


=head2 run($args)

dispatcher to run correspondig C<FML::Command::command> for
C<command>. Standard style follows:

    lock
    execute FML::Command::command
    unlock

XXX Each command determines need of lock or not.

=cut


# Descriptions: call _evaluate_command_lines()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $pcb = $curproc->pcb();
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'command_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    unless ($curproc->is_refused()) {
	# permit_xxx() sets the error reason at "check_restriction" in pcb.
	if ($curproc->permit_command()) {
	    $curproc->_evaluate_command_lines($args);
	}
	# XXX reject command use irrespective of requests from admins/users.
	# XXX rejection of admin use occurs in _evaluate_command_lines()
	# XXX not here.
	# XXX possible cases are from "system_special_accounts" or from a not member.
	else {
	    # check the error reason by permit_command().
	    my $reason = $pcb->get("check_restrictions", "deny_reason");
	    if (defined($reason) && ($reason eq 'reject_system_special_accounts')) {
		my $s = "deny request from system accounts";
		$curproc->reply_message_nl("error.system_special_accounts", $s);
	    }
	    else {
		$curproc->reply_message_nl("error.not_member",
					   "deny request from a not member");
	    }

	    # append the incoming message into the error message sent back
	    # as the reference.
	    my $msg = $curproc->incoming_message();
	    $curproc->reply_message( $msg );

	    # add header info.
	    $curproc->reply_message_add_header_info();

	    unless (defined $reason) { $reason = 'unknown';}
	    $curproc->log("deny command. reason=$reason");
	}
    }
    else {
	$curproc->logerror("ignore this request.");
    }
    $eval = $config->get_hook( 'command_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
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

   For example, process command of elena\@fml.org ML
   $0 elena\@fml.org

_EOF_
}


=head2 finish($args)

queue flush and send back the results or error messages.

=cut


# Descriptions: finalize the command process.
#               reply messages, command results et. al.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: queue manipulation
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'command_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'command_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: check message of the current process
#               whether it contains keyword e.g. "confirm".
#    Arguments: OBJ($curproc) ARRAY_REF($ra_data)
# Side Effects: none
# Return Value: HASH_REF
sub _check_context
{
    my ($curproc, $ra_data) = @_;

    # XXX $ra_data = [ split(/\n/, $message ) ];
    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    my $data  = $check->find_special_keyword($curproc, $ra_data);

    # current process tries to confirm the previous result e.g. subscribe.
    $data->{ under_confirmation } = $data->{ confirm_keyword } ? 1 : 0;

    # XXX-TODO: $data is validated already ?
    # XXX-TODO: e.g. check if "confirm_id" is included in cache?
    return $data;
}


# Descriptions: check command (specified in $opts) is valid and permitted
#               in the configuration.
#    Arguments: OBJ($curproc) STR($level) HASH_REF($opts)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _config_permit_command
{
    my ($curproc, $level, $opts) = @_;
    my $config  = $curproc->config();
    my $cred    = $curproc->{ credential }; # user credential
    my $prompt  = $config->{ command_mail_reply_prompt } || '>>>';
    my $comname = $opts->{ comname };
    my $command = $opts->{ command };

    # XXX-TODO: case sensitive ?
    # use of this command is allowed in FML::Config or not ?
    if ($config->has_attribute("commands_for_$level", $comname)) {
	return 1; # o.k. accpet this command.
    }
    else {
	if ($level eq 'admin' || $level eq 'user') {
	    $curproc->log("commands_for_$level has no $comname");
	    $curproc->reply_message("\n$prompt $command");
	    $curproc->reply_message_nl('command.not_command',
				       "not command, ignored.");
	}
	elsif ($level eq 'stranger') {
	    ; # ignored.
	}
	else {
	    $curproc->logwarn("unknown level=$level");
	}

	return 0;
    }
}


# Descriptions: validate command syntax by FML::Restriction.
#    Arguments: OBJ($curproc) HASH_REF($status) HASH_REF($cominfo)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_safe_syntax
{
    my ($curproc, $status, $cominfo) = @_;
    my $config  = $curproc->config();
    my $prompt  = $config->{ command_mail_reply_prompt } || '>>>';
    my $level   = $status->{ level };
    my $command = $cominfo->{ command };

    # simple command syntax check
    use FML::Restriction::Command;
    if (FML::Restriction::Command::is_secure_command_string( $command )) {
	return 1;
    }
    else {
	if ($level eq 'admin') {
	    $curproc->logerror("insecure command: $command");
	    $curproc->reply_message("\n$prompt $command");
	    $curproc->reply_message_nl('command.insecure',
				       "insecure, so ignored.");
	}
	elsif ($level eq 'stranger' || $level eq 'user') {
	    ; # ignored.
	}
	else {
	    $curproc->logwarn("unknown level=$level");
	}

	return 0;
    }
}


# Descriptions: parse command buffer to prepare several info
#               after use. return info as HASH_REF.
#    Arguments: OBJ($curproc) HASH_REF($args) STR($fixed_command)
# Side Effects: none
# Return Value: HASH_REF
sub _parse_command_args
{
    my ($curproc, $args, $fixed_command) = @_;
    my $config  = $curproc->config();
    my $ml_name = $config->{ ml_name };
    my $argv    = $curproc->command_line_argv();

    my ($comname, $comsubname) = _get_command_name($fixed_command);

    use FML::Command::DataCheck;
    my $check   = new FML::Command::DataCheck;
    my $options = $check->parse_command_arguments($fixed_command, $comname);

    my $cominfo = {
	command    => $fixed_command,
	comname    => $comname,
	comsubname => $comsubname,
	options    => $options,

	ml_name    => $ml_name,
	argv       => $argv,
	args       => $args,

	msg_args   => {},
    };

    return $cominfo;
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
#    Arguments: OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _try_admin_auth
{
    my ($curproc, $optargs) = @_;
    my $is_auth = 0;
    my $obj     = undef;

    eval q{
	use FML::Command::Auth;
	$obj = new FML::Command::Auth;
    };
    unless ($@) {
	my $config = $curproc->config();
	my $rules  = $config->get_as_array_ref('admin_command_restrictions');
	for my $rule (@$rules) {
	    $is_auth = $obj->$rule($curproc, $optargs);

	    # reject as soon as possible
	    if ($is_auth eq '__LAST__') {
		$curproc->log("admin: rejected by $rule");
		return 0;
	    }
	    elsif ($is_auth) {
		$curproc->log("admin: auth by $rule");
		return $is_auth;
	    }
	    else {
		$curproc->log("admin: not match rule=$rule") if $debug;
	    }
	}
    }
    else {
	$curproc->logerror("fail to load FML::Command::Auth");
	return 0;
    }

    # deny transition to admin mode by default
    return 0;
}


# Descriptions: determine $mode and $level for the current command (line).
#               We apply this function for each line in command request.
#               $mode and $level change line by line.
#    Arguments: OBJ($curproc) HASH_REF($status) HAS_REF($command_info)
# Side Effects: update $status, $command_info
# Return Value: STR
sub _get_command_mode
{
    my ($curproc, $status, $command_info) = @_;
    my $config     = $curproc->config();
    my $command    = $command_info->{ command };
    my $comname    = $command_info->{ comname };
    my $comsubname = $command_info->{ comsubname };
    my $is_auth    = $status->{ is_auth };
    my $is_admin   = $status->{ is_admin };
    my $is_member  = $status->{ is_member };
    my $confirm_id = $status->{ context }->{ confirm_keyword };
    my $is_confirm = $status->{ context }->{ under_confirmation };

    # special traps are needed for "confirm" and "admin" commands.
    my $confirm_prefix = $config->{ confirm_command_prefix };
    my $admin_prefix   = $config->{ privileged_command_prefix };

    # cheap sanity
    return '__NEXT__' unless defined $command;
    return '__NEXT__' unless $command;

    # XXX-TODO: $command is clean-ed up already here?
    # XXX-TODO: If so, we should check $command =~ /^$confirm_prefix\s+/ ?
    # XXX-TODO: it is easy for us not to use regexp in this case?

    # Case: "confirm" command. For examle, "confirm ..." or "> confirm ...",
    #        we need to trap all cases including confirm keyword.
    #        It is exceptional so that a stranger can use.
    #        We need to validate commands except for "confirmation"
    #        if $confirm_id is 1, this message must be confirmation reply.
    if ($command =~ /$confirm_prefix\s+/ && $confirm_id) {
	# XXX $command may be "> confirm chaddr ...".
	$comname = $confirm_prefix;          # comname = confirm
	$command =~ s/^.*$comname/$comname/; # normalize $command
	my $opts = { comname => $comname, command => $command };

	# 1. $config permits this command for a stranger?
	# 2. This condition permits "confirm" command for a member,
	#    since $commands_for_stranger contains "confirm" command :-)
	#    It is effective but wrong since we set $level = stranger
	#    though we should set up $level = user.
	if ($curproc->_config_permit_command("stranger", $opts)) {
	    $status->{ mode }  = 'user';
	    $status->{ level } = 'stranger';
	}
	else {
	    # no, we do not accept this command.
	    $curproc->log("invalid command: $command");
	    return '__NEXT__';
	}
    }
    # Case: "admin" command is exceptional. try priviledged mode.
    elsif ($command =~ /$admin_prefix\s+/) {
	if ($is_auth) {
	    $curproc->log("admin: auth-ed already. run <$command>") if $debug;
	}
	else { # for the first time ?
	    $curproc->log("admin: try auth");

	    my $sender  = $curproc->{'credential'}->{'sender'};
	    my $data    = $command;

	    # XXX-TODO: (password|pass) hard-coded.
	    $data =~ s/^.*(password|pass)\s+//;
	    my $optargs = { address => $sender, password => $data };

	    # XXX simple state machine: update $status->{ is_auth }
	    $is_auth = $curproc->_try_admin_auth($optargs);
	    $status->{ is_auth } = $is_auth;
	    $curproc->log("admin: o.k. auth-ed as an ML admin") if $is_auth;
	}

	if ($is_admin && $is_auth) {
	    # XXX-TODO: we need the method normalize_command().
	    $comname = $comsubname;
	    $command =~ s/^.*$comname/admin $comname/;
	    my $opts = { comname => $comname, command => $command };

	    my $xmode = 'privileged_user';
	    if ($curproc->_config_permit_command($xmode, $opts)) {
		$status->{ mode }          = 'admin';
		$status->{ level }         = 'admin';
		$command_info->{ command } = $command;
		$command_info->{ comname } = $comname;
	    }
	    else {
		# no, we do not accept this command.
		$curproc->log("invalid command(priv mode): $command");
		return '__NEXT__';
	    }
	}
	else {
	    # Exapmle: incorrect password
	    if ($is_admin && (! $is_auth)) {
		$status->{ _stop_reason_key } = 'command.auth_fail';
		$status->{ _stop_reason_str } = "not authenticated.";
	    }
	    # Example: not admin member (not in members-admin)
	    elsif ((! $is_admin) && $is_auth) {
		$status->{ _stop_reason_key } = 'error.not_admin_member';
		$status->{ _stop_reason_str } = "not admin member.";
		$curproc->logerror("not admin member");
	    }
	    # other reasons
	    else {
		$status->{ _stop_reason_key } = 'command.auth_fail';
		$status->{ _stop_reason_str } = "not authenticated.";
	    }

	    $curproc->logerror("admin command not authenticated");
	    return '__LAST__';
	}
    }
    # ignore all requests except for confirm command
    # when we receive "confirm" command for better security.
    elsif ($is_confirm) {
	$curproc->log("ignore(confirm stage): $command");
	return '__NEXT__';
    }
    # Case: use command (commands "a usual member" can use)
    else {
	if ($is_member) {
	    my $opts = { comname => $comname, command => $command };
	    if ($curproc->_config_permit_command("user", $opts)) {
		$status->{ mode }  = 'user';
		$status->{ level } = 'user';
	    }
	    else {
		# no, we do not accept this command.
		$curproc->log("invalid command: $command");
		return '__NEXT__';
	    }
	}
	else {
	    my $opts = { comname => $comname, command => $command };
	    if ($curproc->_config_permit_command("stranger", $opts)) {
		$status->{ mode }  = 'user';
		$status->{ level } = 'stranger';
	    }
	    else {
		# XXX invalid condition is satisfied.
		# XXX emergency stop if admin mode.
		if ($status->{ level } eq 'admin') {
		    $curproc->logerror("command from not member.");
		    $curproc->logerror("command processing stop.");
		    return '__LAST__';
		}
		# XXX but just ignore this commnad unless admin mode.
		else {
		    $curproc->log("(debug) ignore $command") if $debug;
		    return '__NEXT__';
		}
	    }
	}
    }

    return $status->{ mode };
}


# Descriptions: this command is allowd under the current $mode and $level
#    Arguments: OBJ($curproc)
#               STR($mode)
#               HASH_REF($status)
#               HASH_REF($command_info)
# Side Effects: none
# Return Value: NUM
sub _config_allow_command
{
    my ($curproc, $mode, $status, $command_info) = @_;
    my $comname = $command_info->{ comname };
    my $config  = $curproc->config();
    my $level   = $status->{ level };

    $curproc->log("(debug) mode=$mode level=$level") if $debug;

    if ($config->has_attribute("commands_for_${level}", $comname)) {
	$curproc->log("(debug) $comname o.k. under mode=$mode level=$level") if $debug;
    }
    else {
	$curproc->log("deny command: mode=$mode level=$level");
	return 0;
    }

    1;
}


=head1 $command_args HASH STRUCTURE

    $command_args  = {
	args                 => HASH_REF,
	argv                 => ARRAY_REF,
	command              => SCALAR,
	command_level        => SCALAR,
	command_mode         => SCALAR,
	comname              => SCALAR,
	comsubname           => SCALAR,
	ml_name              => SCALAR,
	msg_args             => HASH_REF,
	options              => ARRAY_REF,
    };

$command_args hash lives shortly within command processing.

each module in FML::Command::${MODE}::${COMMAND} can use _VARIABLE
within $command_args to share some data between modules called in it.

=cut


# Descriptions: build $command_args for FML::Command execution
#    Arguments: OBJ($curproc) HASH_REF($status) HASH_REF($cominfo)
# Side Effects: none
# Return Value: HASH_REF
sub _gen_command_args
{
    my ($curproc, $status, $cominfo) = @_;
    my $xargs = $cominfo;
    my $mode  = $status->{ mode };
    $xargs->{ command_mode }  = $status->{ mode };
    $xargs->{ command_level } = $status->{ level };

    # we need to modify [ $comsubname, @options ] to [ @options ]
    if ($mode eq 'admin' && @{ $xargs->{ options } }) {
	shift @{ $xargs->{ options } };
    }

    return $xargs;
}


# Descriptions: remove the superflous string before the actual command
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub __clean_up
{
    my ($buf) = @_;
    $buf =~ s/^\W+//;
    return $buf;
}


# Descriptions: set up error message to inform emergency stop
#    Arguments: OBJ($curproc)
#               HASH_REF($status) HASH_REF($cominfo) STR($orig_command)
# Side Effects: update reply messages
# Return Value: none
sub __stop_here
{
    my ($curproc, $status, $cominfo, $orig_command) = @_;
    my $config  = $curproc->config();
    my $prompt  = $config->{ command_mail_reply_prompt } || '>>>';
    my $key     = $status->{ _stop_reason_key };
    my $str     = $status->{ _stop_reason_str };

    use FML::Command;
    my $obj = new FML::Command;
    if (defined $obj) {
	# rewrite prompt e.g. to hide the password
	my $command_args = $curproc->_gen_command_args($status, $cominfo);
	$obj->rewrite_prompt($curproc, $command_args, \$orig_command);
	$curproc->reply_message("\n$prompt $orig_command");
	$curproc->reply_message_nl($key, $str);
	$curproc->reply_message_nl('command.stop', "stopped.");
    }
}


# Descriptions: scan message body and execute approviate command
#               with dynamic loading of command definition.
#               It resolves your customized command easily.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: loading FML::Command::command.
#               prepare messages to return.
# Return Value: none
sub _evaluate_command_lines
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->config();
    my $ml_name = $config->{ ml_name };
    my $argv    = $curproc->command_line_argv();
    my $prompt  = $config->{ command_mail_reply_prompt } || '>>>';
    my $mode    = 'unknown';
    my $rbody   = $curproc->incoming_message_body();
    my $msg     = $rbody->find_first_plaintext_message();

    # preliminary scanning for message to find "confirm" or "admin"
    my $command_lines = $msg->message_text_as_array_ref();
    my $context       = $curproc->_check_context($command_lines);

    # [user credential check]
    #     is_admin: whether From: is a member of admin users.
    #      is_auth: authenticated or not by e.g. password
    my $cred      = $curproc->{ credential };
    my $sender    = $cred->sender();
    my $is_member = $cred->is_member($sender);
    my $is_admin  = $cred->is_privileged_member($sender);
    my $is_auth   = 0;
    my $status    = {
	is_auth        => $is_auth,
	is_admin       => $is_admin,
	is_member      => $is_member,
	mode           => $mode,
	level          => 'unknown',
	context        => $context,
    };


    my $eval = $config->get_hook( 'command_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # firstly, prompt (for politeness :) to show processing ...
    $curproc->reply_message("result for your command requests follows:");

    # the main loop to analyze each command at each line.
    my ($cominfo, $fixed_command);
    my ($num_total, $num_ignored, $num_processed) = (0, 0, 0);
    my $is_cc_recipient = 1;
    my %cc_recipient    = ();
  COMMAND:
    for my $orig_command (@$command_lines) {
	next COMMAND if $orig_command =~ /^\s*$/; # ignore empty lines

	$num_total++; # the total numer of non null lines

	$curproc->log("(debug) input: $orig_command") if $debug; # log raw buffer

	# Example: if orig_command = "# help", comname = "help"
	$fixed_command = __clean_up($orig_command);
	$cominfo       = $curproc->_parse_command_args($args, $fixed_command);
	$mode          = $curproc->_get_command_mode($status, $cominfo);

	# 1. check $mode if the further processing is allowed
	if ($mode eq '__NEXT__') {
	    $num_ignored++;
	    next COMMAND;
	}
	elsif ($mode eq '__LAST__') {
	    $curproc->logerror("command processing stop.");
	    $curproc->__stop_here($status, $cominfo, $orig_command);
	    last COMMAND;
	}


	# [CAUTION]
	#    mode  = { user, admin };
	#    level = { strange, user, admin };


	# 1.3 valid mode
	unless ($mode eq 'user' || $mode eq 'admin') {
	    $curproc->logerror("command processing stop.");
	    $curproc->__stop_here($status, $cominfo, $orig_command);
	    last COMMAND;
	}

	# 2. check $level if this command is allowed in the current $mode ?
	unless ($curproc->_config_allow_command($mode, $status, $cominfo)) {
	    $curproc->reply_message_nl("command.deny",
				    "\tyou cannot use this command.");
	    $curproc->log("(debug) ignore $fixed_command");
	    $num_ignored++;
	    next COMMAND;
	}

	# 3. simple syntax check
	unless ($curproc->_is_safe_syntax($status, $cominfo)) {
	    $curproc->logerror("invalid/unsafe syntax");
	    $curproc->log("(debug) ignore $fixed_command");
	    $num_ignored++;
	    next COMMAND;
	}

	# o.k. here we go to execute this command
	$curproc->log("execute \"$fixed_command\"") if $debug;
	$num_processed++;

	use FML::Command;
	my $obj = new FML::Command;
	if (defined $obj) {
	    # arguments to pass off into each method
	    my $sender       = $curproc->{'credential'}->{'sender'};
	    my $command_args = $curproc->_gen_command_args($status, $cominfo);
	    my $msg_args     = $command_args->{ msg_args };
	    $msg_args->{ always_cc } = $sender;

	    # rewrite prompt e.g. to hide the password
	    $obj->rewrite_prompt($curproc, $command_args, \$orig_command);

	    # check if addresses to notice defined ?
	    # XXX The recipients are dependent on each command.
	    # XXX Defined in each command module (e.g. FML::Command::User::*)
	    {
		my $a = $obj->notice_cc_recipient($curproc, $command_args);
		if (defined $a) {
		    $msg_args->{ recipient } = $a;
		    $is_cc_recipient = 1;
		    $cc_recipient{ join("-", @$a) } = $a;
		}
	    }

	    # reply buffer
	    $curproc->reply_message("\n$prompt $orig_command", $msg_args);
	    $curproc->log($orig_command);

	    # execute command ($comname method) under eval().
	    # XXX $obj = FML::Command object NOT FML::Command::$mode::$command
	    # XXX-TODO: validate $comname is safe syntax or not.
	    my $comname = $cominfo->{ comname };
	    eval q{
		$obj->$comname($curproc, $command_args);
	    };
	    unless ($@) {
		$curproc->reply_message_nl('command.ok', "ok.", $msg_args);
	    }
	    else { # error trap
		my $reason = $@;
		$curproc->log($reason);

		$curproc->reply_message_nl('command.fail', "fail.", $msg_args);
		$curproc->logerror("command ${comname} fail");

		if ($reason =~ /^(.*)\s+at\s+/) {
		    my $reason = $1;
		    $curproc->log($reason); # pick up reason
		}
	    }
	}
    } # END OF FOR LOOP: for my $orig_command (@body) { ... }

    $eval = $config->get_hook( 'command_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # info
    $curproc->reply_message("\ncommand processing results:");
    $curproc->reply_message("   processed = $num_processed");
    $curproc->reply_message("   ignored   = $num_ignored");
    $curproc->reply_message("   total     = $num_total");

    # send back the original input message if needed.
    {
	my $msg = $curproc->incoming_message();

	# in the case "confirm"
	if ($status->{ context }->{ under_confirmation }) {
	    # send back original message as a reference
	    $curproc->reply_message( $msg );
	}

	if (keys %cc_recipient) {
	    for my $k (keys %cc_recipient) {
		my $ra_addr = $cc_recipient{ $k };
		$curproc->log("msg.cc: [ @$ra_addr ]");
		$curproc->reply_message( $msg , { recipient => $ra_addr });
	    }
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
