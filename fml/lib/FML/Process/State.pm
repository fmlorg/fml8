#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: State.pm,v 1.2 2004/03/04 04:30:14 fukachan Exp $
#

package FML::Process::State;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Process::State - interface to handle states within this process

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=haed1 BASIC RESTRICTION STATES

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

    $curproc->log("restriction_state_set_deny_reason: $reason");
}


# Descriptions: return the latest reason on denial.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub restriction_state_get_deny_reason
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    $pcb->get("check_restrictions", "deny_reason");
}


# Descriptions: send message on the latest reason on denial.
#    Arguments: OBJ($curproc) STR($type) HASH_REF($msg_args)
# Side Effects: none
# Return Value: none
sub restriction_state_reply_reason
{
    my ($curproc, $type, $msg_args) = @_;

    my $rule = $curproc->restriction_state_get_deny_reason();

    $curproc->log("restriction_state_reply_reason: $rule");

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


=haed1 COMMAND PROCESSOER STATES

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
    my $cleanstr = _command_string_clean_up($orig_command);
    my $context  = $curproc->_build_command_context_template($cleanstr);

    # save original string, set the command mode be "user" by default.
    $context->{ command_mode }     = "User";
    $context->{ original_command } = $orig_command;

    # reset error reason
    $curproc->restriction_state_set_deny_reason('');

    return $context;
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
#    Arguments: STR($buf)
# Side Effects: none
# Return Value: STR
sub _command_string_clean_up
{
    my ($buf) = @_;
    $buf =~ s/^\W+//o;
    return $buf;
}


# Descriptions: declare no more further command processing needed.
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


# Descriptions: set "we need to send back confirmation".
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "need_confirm", 1);
}


# Descriptions: check if we need to send back confirmation ?
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_need_confirm
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "need_confirm") || 0 );
}


# Descriptions: remote administrator is authenticated.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb.
# Return Value: NUM
sub command_context_set_admin_auth
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "admin_auth", 1);
}


# Descriptions: check if remote administrator is authenticated.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM
sub command_context_get_admin_auth
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "admin_auth") || 0 );
}


# Descriptions: store password on memory for later use.
#    Arguments: OBJ($curproc) STR($password)
# Side Effects: update pcb.
# Return Value: STR
sub command_context_set_admin_password
{
    my ($curproc, $password) = @_;
    my $pcb = $curproc->pcb();

    $pcb->set("process_command", "admin_password", $password);
}


# Descriptions: retrive stored password on memory.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub command_context_get_admin_password
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();

    return( $pcb->get("process_command", "admin_password") || '' );
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
#    Arguments: OBJ($curproc) STR($class)
# Side Effects: none
# Return Value: none
sub error_message_set_count
{
    my ($curproc, $class) = @_;
    my $pcb   = $curproc->pcb();

    my $count = $pcb->get("reply_messaged_count", $class) || 0;
    $pcb->set("reply_messaged_count", $class, $count + 1);
}


# Descriptions: get error count on this class $class
#               to avoid duplicated error messages.
#    Arguments: OBJ($curproc) STR($class)
# Side Effects: none
# Return Value: none
sub error_message_get_count
{
    my ($curproc, $class) = @_;
    my $pcb = $curproc->pcb();

    return $pcb->get("reply_messaged_count", $class) || 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::State appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
