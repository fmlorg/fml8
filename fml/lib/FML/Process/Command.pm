#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Command.pm,v 1.107 2004/05/25 03:39:00 fukachan Exp $
#

package FML::Process::Command;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


my ($num_total, $num_error, $num_ignored, $num_processed) = (0, 0, 0, 0);
my %cc_recipient = ();


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

    my $eval = $config->get_hook( 'command_mail_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    if ($config->yes('use_command_mail_function')) {
	$curproc->parse_incoming_message();
    }
    else {
	$curproc->logerror("use of command_mail_program prohibited");
	exit(0);
    }

    $eval = $config->get_hook( 'command_mail_prepare_end_hook' );
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

    my $eval = $config->get_hook( 'command_mail_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->verify_sender_credential();

    unless ($curproc->is_refused()) {
	$curproc->_check_filter();
    }

    $eval = $config->get_hook( 'command_mail_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: apply several filters.
#    Arguments: OBJ($curproc)
# Side Effects: set flag to ignore this process if it should be filtered.
# Return Value: none
sub _check_filter
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    my $eval = $config->get_hook( 'command_mail_filter_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    eval q{
	use FML::Filter;
	my $filter = new FML::Filter $curproc;
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

    $eval = $config->get_hook( 'command_mail_filter_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

dispatcher to run correspondig C<FML::Command::command> for
C<command>. Standard style follows:

    lock
    execute FML::Command::command
    unlock

XXX Each command determines need of lock or not.

=cut


# Descriptions: call _evaluate_command_lines().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $pcb    = $curproc->pcb();
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'command_mail_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    unless ($curproc->is_refused()) {
	$curproc->_command_process_loop();
	$curproc->_add_reply_message_trailor();
    }
    else {
	$curproc->logerror("ignore this request.");
    }

    $eval = $config->get_hook( 'command_mail_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

show help.

=cut


# Descriptions: show help.
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

    my $eval = $config->get_hook( 'command_mail_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'command_mail_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head1 LOCAL LIBRARIES

=cut


# Descriptions: scan message body and call command switch (wrapper).
#    Arguments: OBJ($curproc)
# Side Effects: loading FML::Command::command.
#               prepare messages to return.
# Return Value: none
sub _command_process_loop
{
    my ($curproc) = @_;
    my $ml_domain = $curproc->ml_domain();
    my $config    = $curproc->config();
    my $rbody     = $curproc->incoming_message_body();
    my $msg       = $rbody->find_first_plaintext_message();
    my $comlines  = $msg->message_text_as_array_ref();
    my $context   = {};

    # firstly, prompt (for politeness :) to show processing ...
    {
	my $whoami    = "Hi, I am fml8 system for $ml_domain domain.";
	my $result_is = "result for your command requests follows:";
	$curproc->reply_message_nl("system.whoami",  $whoami);
	$curproc->reply_message_nl("command.result", $result_is);
    }

    # the main loop to analyze each command at each line.
  COMMAND:
    for my $orig_command (@$comlines) {
	next COMMAND if $orig_command =~ /^\s*$/o; # ignore empty lines

	$num_total++; # the total numer of non null lines

	if ($debug) { # save raw command buffer.
	    $curproc->log("(debug) input[$num_total]: $orig_command");
	}

	# XXX analyze the iput command and set info into $context.
	$context = $curproc->command_context_init($orig_command);

	# if $context is empty HASH_REF, no valid command in this line.
	if (defined $context->{ comname }) {
	    # XXX call command actually.
	    $curproc->_command_switch($context);
	}
	else {
	    $num_ignored++;
	}

	# XXX error handlings.
	# 1. stop here e.g. we processed "unsubscribe" above, so stop here.
	if ($curproc->command_context_get_normal_stop()) {
	    $curproc->reply_message_nl('command.stop', "stopped.");
	    $curproc->log("command processing stop.");
	    last COMMAND;
	}

	# 2. command evaluation ends.
	#    it should be notified by using $curproc->stop_this_process().
	if ($curproc->command_context_get_stop_process()) {
	    $curproc->logerror("command processing stop.");
	    $curproc->reply_message_nl('command.stop', "stopped.");
	    last COMMAND;
	}
    }
}


# Descriptions: check configuration. if ok, call each command
#               via _command_execute().
#    Arguments: OBJ($curproc) HASH_REF($context)
# Side Effects: none
# Return Value: none
sub _command_switch
{
    my ($curproc, $context) = @_;
    my $config   = $curproc->config();
    my $prompt   = $config->{ command_mail_reply_prompt } || '>>>';
    my $cred     = $curproc->{ credential }; # user credential
    my $sender   = $cred->sender();
    my $comname  = $context->{ comname };
    my $msg_args = $context->{ msg_args } || {};

    if ($debug) {
	my $fixed_command = $context->{ fixed_command };
	$curproc->log("execute \"$fixed_command\"");
    }

    # command restriction rules
    use FML::Restriction::Command;
    my $acl   = new FML::Restriction::Command $curproc;
    my $rules = $config->get_as_array_ref('command_mail_restrictions');
    my ($match, $result) = (0, 0);
  RULE:
    for my $rule (@$rules) {
	if ($acl->can($rule)) {
	    # match  = matched. return as soon as possible from here.
	    #          ASAP or RETRY the next rule, depends on the rule.
	    # result = action determined by matched rule.
	    ($match, $result) = $acl->$rule($rule, $sender, $context);
	}
	else {
	    ($match, $result) = (0, undef);
	    $curproc->logwarn("unknown rule=$rule");
	}

	if ($match) {
	    $curproc->log("$result rule=$rule");
	    last RULE;
	}
    }

    if ($match) {
	my $option  = $context->{ option } || [];
	my $cont    = $option->[ 1 ] ? "..." : "";
	my $_prompt = "$prompt $comname $cont";

	if ($result eq "permit") {
	    $curproc->_command_execute($context);
	}
	elsif ($result eq "deny") {
	    $num_error++;
	    $curproc->log("deny command: $comname");
	    $curproc->reply_message("\n$_prompt");
	    $curproc->restriction_state_reply_reason('command_mail',
						     $msg_args);
	}
	else {
	    $num_ignored++;
	    $curproc->reply_message("\n$_prompt");
	    $curproc->reply_message_nl("command.not_command", 
				       "no such command.",
				       $msg_args);
	    $curproc->log("ignore command: $comname");
	}
    }
    else {
	$num_ignored++;
	$curproc->logerror("match no restriction rule: $comname");
	$curproc->reply_message("   ignored.", $msg_args);
    }
}


# Descriptions: actually execute command via FML::Command.
#    Arguments: OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub _command_execute
{
    my ($curproc, $command_args) = @_;
    my $config   = $curproc->config();
    my $prompt   = $config->{ command_mail_reply_prompt } || '>>>';
    my $cred     = $curproc->{ credential };
    my $sender   = $cred->sender();
    my $msg_args = $command_args->{ msg_args } || {};

    use FML::Command;
    my $dispatch = new FML::Command;
    if (defined $dispatch) {
	# XXX-TODO: configurable
	# always cc to the sender.
	if (1) {
	    $msg_args->{ always_cc } = $sender;
	}

	# command dependent rewrite prompt e.g. to hide the password
	my $masked_command = $command_args->{ original_command };
	$dispatch->rewrite_prompt($curproc, $command_args, \$masked_command);
        $command_args->{ masked_original_command } = $masked_command;

	# recipients depends on each command. The list is defined in
	# each command module (e.g. FML::Command::User::*)
	my $cclist = $dispatch->notice_cc_recipient($curproc, $command_args);
	if (defined $cclist && @$cclist) {
	    my $primary_key = join("-", sort @$cclist); # XXX unique key.
	    $msg_args->{ recipient }      = $cclist;
	    $cc_recipient{ $primary_key } = $cclist;
	}

	# bulid reply buffer, which is rewritten if needed above.
	$curproc->reply_message("\n$prompt $masked_command", $msg_args);
	$curproc->log("command: $masked_command");

	# command dependent syntax checker.
	unless ($dispatch->verify_syntax($curproc, $command_args)) {
	    $curproc->reply_message_nl('command.insecure', 
				       "stopped due to insecure syntax.",
				       $msg_args);
	    $curproc->logerror("insecure syntax: \"$masked_command\"");
	    return 0;
	}

	# execute $comname command within eval().
	# 1) $dispatch = FML::Command NOT FML::Command::$mode::$command
	# 2) $comname must be valid since $comname is one of defined
	#    command list in $config (see _command_switch() method).
	my $comname = $command_args->{ comname };
	eval q{
	    $dispatch->$comname($curproc, $command_args);
	};
	unless ($@) {
	    $num_processed++;
	    $curproc->reply_message_nl('command.ok', "ok.", $msg_args);
	}
	else { # error trap
	    my $reason = $@;
	    $curproc->log($reason);

	    $num_error++;

	    $curproc->reply_message_nl('command.fail', "fail.", $msg_args);
	    $curproc->logerror("command ${comname} fail");

	    if ($reason =~ /^(.*)\s+at\s+/) {
		my $reason = $1;
		$curproc->log($reason); # pick up reason
	    }
	}
    }
}


# Descriptions: add closing message at the tail of result.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _add_reply_message_trailor
{
    my ($curproc) = @_;

    # info
    $curproc->reply_message("\ncommand processing results:");
    $curproc->reply_message("   processed = $num_processed");
    $curproc->reply_message("   error     = $num_error");
    $curproc->reply_message("   ignored   = $num_ignored");
    $curproc->reply_message("   total     = $num_total");

    # send back the original input message if needed.
    my $msg = $curproc->incoming_message();

    # 1. send back original message as a reference in the case "confirm".
    if ($curproc->command_context_get_need_confirm()) {
	$curproc->reply_message( $msg );
    }

    # 2. if cc (carbon copy) is needed.
    if (keys %cc_recipient) {
	for my $k (keys %cc_recipient) {
	    my $ra_addr = $cc_recipient{ $k };
	    $curproc->log("msg.cc: [ @$ra_addr ]");
	    $curproc->reply_message( $msg , { recipient => $ra_addr });
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Command first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
