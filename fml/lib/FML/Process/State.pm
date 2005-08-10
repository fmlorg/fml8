#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: State.pm,v 1.21 2005/06/04 08:49:11 fukachan Exp $
#

package FML::Process::State;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;


=head1 NAME

FML::Process::State - interface to handle states within current process.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 CURRENT MAILING LIST

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub current_process_init
{
    my ($curproc) = @_;

}


# Descriptions: set ml_name to handle currently.
#    Arguments: OBJ($curproc) STR($ml_name)
# Side Effects: update pcb.
# Return Value: none
sub current_process_set_ml_name
{
    my ($curproc, $ml_name) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("current_process", "ml_name", $ml_name);
}


# Descriptions: get ml_name to handle currently.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub current_process_get_ml_name
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("current_process", "ml_name");
}


=head1 BASIC RESTRICTION STATES

CAUTION: restriction_state_*() is reset each command.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub restriction_state_init
{
    my ($curproc) = @_;

}


# Descriptions: save reason on denial.
#    Arguments: OBJ($curproc) STR($reason)
# Side Effects: none
# Return Value: none
sub restriction_state_set_deny_reason
{
    my ($curproc, $reason) = @_;
    my $pcb = $curproc->pcb();
    $pcb->set("check_restrictions", "deny_reason", $reason);

    $curproc->logdebug("restriction_state_set_deny_reason: $reason") if $debug;
}


# Descriptions: return the latest reason on denial.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub restriction_state_get_deny_reason
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("check_restrictions", "deny_reason");
}


# Descriptions: send message on the latest reason on denial.
#    Arguments: OBJ($curproc) STR($type) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub restriction_state_reply_reason
{
    my ($curproc, $type, $msg_args) = @_;

    my $rule = $curproc->restriction_state_get_deny_reason();

    $curproc->logdebug("restriction_state_reply_reason: $rule") if $debug;

    if ($rule eq 'reject_system_special_accounts') {
	my $r = "deny request from a system account";
	$curproc->reply_message_nl("error.system_special_accounts",
				   $r, $msg_args);
    }
    elsif ($rule eq 'permit_member_maps') {
	my $r = "denied since you are not a member";
	if ($type eq 'command_mail') {
	    $curproc->reply_message_nl("command.deny", $r, $msg_args);
	}

	my $count = $curproc->error_message_get_count("error.not_member");
	unless ($count) {
	    $curproc->reply_message_nl("error.not_member", $r, $msg_args);
	    $curproc->error_message_set_count("error.not_member");
	}
    }
    elsif ($rule eq 'permit_user_command') {
	my $r = "you are not allowed to use this command.";
	$curproc->reply_message_nl("command.deny", $r, $msg_args);
    }
    elsif ($rule eq 'reject') {
	my $r = "deny your request";
	if ($type eq 'article_post') {
	    $curproc->reply_message_nl("error.reject_post", $r, $msg_args);
	}
	elsif ($type eq 'command_mail') {
	    $curproc->reply_message_nl("error.reject_command", $r, $msg_args);
	}
    }
    else {
	my $r = "deny your request due to an unknown reason";
	if ($type eq 'article_post') {
	    $curproc->reply_message_nl("error.reject_post", $r, $msg_args);
	}
	elsif ($type eq 'command_mail') {
	    $curproc->reply_message_nl("error.reject_command", $r, $msg_args);
	}
    }
}


=head1 ARTICLE STATES

=cut


# Descriptions: set the current article id on current process.
#    Arguments: OBJ($curproc) NUM($id)
# Side Effects: update pcb.
# Return Value: NUM
sub article_set_id
{
    my ($curproc, $id) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("article_message", "id", $id);
}


# Descriptions: get the current article id on current process.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub article_get_id
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("article_message", "id");
}


=head1 COMMAND PROCESSOER STATES

command_context_init() called for each command, so
restriction_state_*() is reset each time.

But in the case of emulatation of listserv/majordomo emulation, we
should pay attention for handlings of $command_mail_restrictions and
$admin_command_mail_restrictions. The restrictions must differ among
mailing lists. So, we do not cache the return value and always check
it each command mail line.

=cut


# Descriptions: parse $orig_command and set up HASH_REF as
#               base information for command processing.
#    Arguments: OBJ($curproc) STR($orig_command)
# Side Effects: none
# Return Value: HASH_REF
sub command_context_init
{
    my ($curproc, $orig_command) = @_;

    # Example: if orig_command = "# help", comname = "help"
    my $cleanstr = $curproc->_command_string_clean_up($orig_command);
    my $context  = $curproc->_build_command_context_template($cleanstr);

    # save original string, set the command mode be "user" by default.
    $context->{ command_mode }     = "User";
    $context->{ original_command } = $orig_command;

    # reset error reason
    $curproc->restriction_state_set_deny_reason('');

    # declare current mailing list.
    my $ml_name = $curproc->ml_name();
    $curproc->command_context_set_ml_name($ml_name);

    # check if command is valid.
    my $found = 0;
    my $name  = $context->{ comname } || '';
    if ($name) {
	my $config = $curproc->config();

      LIST:
	for my $list (qw(anonymous_command_mail_allowed_commands
			 user_command_mail_allowed_commands)) {
	    if ($config->has_attribute($list, $name)) {
		$found = 1;
		last LIST;
	    }
	}
    }

    # if valid, return the current context (HASH_REF).
    if ($found) {
	return $context;
    }
    else {
	return {};
    }
}


# Descriptions: parse command buffer to prepare several info
#               after use. return info as HASH_REF.
#    Arguments: OBJ($curproc) STR($fixed_command)
# Side Effects: none
# Return Value: HASH_REF
sub _build_command_context_template
{
    my ($curproc, $fixed_command) = @_;
    my $ml_name   = $curproc->ml_name();
    my $ml_domain = $curproc->ml_domain();
    my $argv      = $curproc->command_line_argv();

    use FML::Command::DataCheck;
    my $check = new FML::Command::DataCheck;
    my ($comname, $comsubname) = $check->parse_command_buffer($fixed_command);
    my $options = $check->parse_command_arguments($fixed_command, $comname);
    my $cominfo = {
	command    => $fixed_command,
	comname    => $comname,
	comsubname => $comsubname,
	options    => $options,

	ml_name    => $ml_name,
	ml_domain  => $ml_domain,
	argv       => $argv,

	msg_args   => {},
    };

    return $cominfo;
}


# Descriptions: remove the superflous string before the actual command.
#    Arguments: OBJ($curproc) STR($buf)
# Side Effects: none
# Return Value: STR
sub _command_string_clean_up
{
    my ($curproc, $buf) = @_;
    my $config          = $curproc->config();
    my $confirm_prefix  = $config->{ confirm_command_prefix };

    $buf =~ s/^\W+$confirm_prefix/$confirm_prefix/;
    return $buf;
}


# Descriptions: set the current $ml_name.
#    Arguments: OBJ($curproc) STR($ml_name)
# Side Effects: update pcb.
# Return Value: STR
sub command_context_set_ml_name
{
    my ($curproc, $ml_name) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "ml_name", $ml_name);
}


# Descriptions: return the current $ml_name.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub command_context_get_ml_name
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "ml_name") || '' );
}


# Descriptions: declare no more further command processing needed
#               due to critical error.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_stop_process
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "stop_now", 1);
}


# Descriptions: we stop here or not ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_stop_process
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "stop_now") || 0 );
}


# Descriptions: declare no more further command processing needed.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_normal_stop
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "normal_stop", 1);
}


# Descriptions: we stop here or not ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_normal_stop
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "normal_stop") || 0 );
}


# Descriptions: set "we need to send back confirmation".
#               usually, this flag means we send back the original message.
#               hence, this flag is universal over plural ML's.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    # XXX-TODO: correct ? this flag is universal over plural ML's.
    $pcb->set("process_command", "need_confirm", 1);
}


# Descriptions: check if we need to send back confirmation ?
#               usually, this flag means we send back the original message.
#               hence, this flag is universal over plural ML's.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    # XXX-TODO: correct ? this flag is universal over plural ML's.
    return( $pcb->get("process_command", "need_confirm") || 0 );
}


# Descriptions: remote administrator is authenticated.
#               state is ml specific.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_admin_auth
{
    my ($curproc) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("admin_auth_ml_name=%s", $cur_ml);

    $pcb->set("process_command", $class, 1);
}


# Descriptions: check if remote administrator is authenticated.
#               state is ml specific.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_admin_auth
{
    my ($curproc) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("admin_auth_ml_name=%s", $cur_ml);

    return( $pcb->get("process_command", $class) || 0 );
}


# Descriptions: store password on memory for later use.
#    Arguments: OBJ($curproc) STR($password)
# Side Effects: update pcb.
# Return Value: STR
sub command_context_set_admin_password
{
    my ($curproc, $password) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("admin_password_ml_name=%s", $cur_ml);

    $pcb->set("process_command", "admin_password", $password);
}


# Descriptions: retrive stored password on memory.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub command_context_get_admin_password
{
    my ($curproc) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("admin_password_ml_name=%s", $cur_ml);

    return( $pcb->get("process_command", "admin_password") || '' );
}


# Descriptions: remote administrator is authenticated.
#               state is ml specific.
#    Arguments: OBJ($curproc) NUM($req)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_try_admin_auth_request
{
    my ($curproc, $req) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("try_admin_auth_request_ml_name=%s", $cur_ml);

    $pcb->set("process_command", $class, 1);
}


# Descriptions: remote administrator is authenticated.
#               state is ml specific.
#    Arguments: OBJ($curproc) NUM($req)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_reset_try_admin_auth_request
{
    my ($curproc, $req) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("try_admin_auth_request_ml_name=%s", $cur_ml);

    $pcb->set("process_command", $class, 0);
}


# Descriptions: check if remote administrator is authenticated.
#               state is ml specific.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_try_admin_auth_request
{
    my ($curproc) = @_;
    my $pcb    = $curproc->pcb();
    my $cur_ml = $curproc->command_context_get_ml_name();
    my $class  = sprintf("try_admin_auth_request_ml_name=%s", $cur_ml);

    return( $pcb->get("process_command", $class) || 0 );
}


=head1 FILTER STATE

=head2 filter_state_set_error($category, $code)

save the filter error for later use.

=head2 filter_state_get_error($category)

get the filter error.

=cut


# Descriptions: save the filter error for later use.
#    Arguments: OBJ($curproc) STR($category) STR($code)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_set_error
{
    my ($curproc, $category, $code) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("filter_state", $category, $code || 0);
}


# Descriptions: get the filter error.
#    Arguments: OBJ($curproc) STR($category)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_get_error
{
    my ($curproc, $category) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("filter_state", $category) || 0 );
}


# Descriptions: save the spam filter error for later use.
#    Arguments: OBJ($curproc) STR($code)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_spam_checker_set_error
{
    my ($curproc, $code) = @_;
    my $category = "spam_checker";
    my $pcb = $curproc->pcb();

    $pcb->set("filter_state", $category, $code || 0);
}


# Descriptions: get the spam filter error.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_spam_checker_get_error
{
    my ($curproc) = @_;
    my $category  = "spam_checker";
    my $pcb = $curproc->pcb();

    return( $pcb->get("filter_state", $category) || 0 );
}


# Descriptions: save the virus filter error for later use.
#    Arguments: OBJ($curproc) STR($code)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_virus_checker_set_error
{
    my ($curproc, $code) = @_;
    my $category = "virus_checker";
    my $pcb = $curproc->pcb();

    $pcb->set("filter_state", $category, $code || 0);
}


# Descriptions: get the virus filter error.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_virus_checker_get_error
{
    my ($curproc) = @_;
    my $category = "virus_checker";
    my $pcb = $curproc->pcb();

    return( $pcb->get("filter_state", $category) || 0 );
}


# Descriptions: we need to exit as EX_TEMPFAIL.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: none
sub filter_state_set_tempfail_request
{
    my ($curproc) = @_;
    my $category = "exit_tempfail";
    my $pcb = $curproc->pcb();

    $pcb->set("filter_state", $category, 1);
}


# Descriptions: check if we need to exit as EX_TEMPFAIL.
#    Arguments: OBJ($curproc)
# Side Effects: none.
# Return Value: NUM
sub filter_state_get_tempfail_request
{
    my ($curproc) = @_;
    my $category  = "exit_tempfail";
    my $pcb = $curproc->pcb();

    return( $pcb->get("filter_state", $category) || 0 );
}


=head1 SMTP STATE

=head2 smtp_server_state_set_error($mta)

set $mta as error for later hint.

=head2 smtp_server_state_get_error()

check if $mta as error for later hint.

=cut


# Descriptions: set $mta as error for later hint.
#               implies "all servers" unless $mta specified.
#    Arguments: OBJ($curproc) STR($mta)
# Side Effects: update pcb.
# Return Value: none
sub smtp_server_state_set_error
{
    my ($curproc, $mta) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("smtp_transaction", $mta || "ALL", "error");
}


# Descriptions: check if $mta as error for later hint.
#               implies "all servers" unless $mta specified.
#    Arguments: OBJ($curproc) STR($mta)
# Side Effects: update pcb.
# Return Value: NUM(1 or 0)
sub smtp_server_state_get_error
{
    my ($curproc, $mta) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("smtp_transaction", $mta || "ALL") ? 1 :  0 );
}


=head1 UTILITY

=head2 error_message_set_count($class)

increment error count on this class $class to avoid duplicated error
messages.

=head2 error_message_get_count($class)

get error count on this class $class to avoid duplicated error
messages.

=cut


# Descriptions: increment error count on this class $class
#               to avoid duplicated error messages.
#               hence, this flag is universal over plural ML's.
#    Arguments: OBJ($curproc) STR($class)
# Side Effects: none
# Return Value: none
sub error_message_set_count
{
    my ($curproc, $class) = @_;
    my $pcb   = $curproc->pcb();

    my $count = $pcb->get("reply_message_count", $class) || 0;
    $pcb->set("reply_message_count", $class, $count + 1);
}


# Descriptions: get error count on this class $class
#               to avoid duplicated error messages.
#               hence, this flag is universal over plural ML's.
#    Arguments: OBJ($curproc) STR($class)
# Side Effects: none
# Return Value: none
sub error_message_get_count
{
    my ($curproc, $class) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("reply_message_count", $class) || 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::State appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
