#-*- perl -*-
#
# Copyright (C) 2000,2001,2002 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Command.pm,v 1.27 2002/01/16 13:34:00 fukachan Exp $
#

package FML::Process::Command;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

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
    $self->SUPER::prepare($args);
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
    $curproc->verify_sender_credential();
}


=head2 C<run($args)>

dispatcher to run correspondig C<FML::Command::command> for
C<command>. Standard style follows:

    lock
    execute FML::Command::command
    unlock

=cut


# Descriptions: call _evaluate_command()
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    $curproc->_evaluate_command($args);
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

    $curproc->inform_reply_messages();
    $curproc->queue_flush();
}


# Descriptions: check message of the current process
#               whether it contais keyword e.g. "confirm".
#    Arguments: OBJ($self) STR_REF($ra_body)
# Side Effects: none
# Return Value: STR or 0
sub _pre_scan
{
    my ($curproc, $ra_body) = @_;
    my $config  = $curproc->{ config };
    my $keyword = $config->{ confirm_keyword };
    my $found   = 0;

    for (@$ra_body) {
	if (/$keyword\s+\w\s+([\w\d]+)/) {
	    $found = $1;
	}
    }

    return $found;
}


# Descriptions: check command (specified in $opts) content:
#               syntax check, permission of command use et. al.
#    Arguments: OBJ($self) HASH_REF($args) HASH_REF($opts)
# Side Effects: none
# Return Value: 1 or 0
sub _can_accpet_command
{
    my ($curproc, $args, $opts) = @_;
    my $config  = $curproc->{ config };
    my $cred    = $curproc->{ credential }; # user credential
    my $prompt  = $config->{ command_prompt } || '>>>';
    my $comname = $opts->{ comname };
    my $command = $opts->{ command };

    # 1. simple command syntax check
    use FML::Filter::Utils;
    unless ( FML::Filter::Utils::is_secure_command_string( $command ) ) {
	LogError("insecure command: $command");
	$curproc->reply_message("\n$prompt $command");
	$curproc->reply_message_nl('command.insecure',
				   "insecure, so ignored.");
	return 0;
    }

    # 2. use of this command is allowed in FML::Config or not ?
    unless ($config->has_attribute("available_commands", $comname)) {
	$curproc->reply_message("\n$prompt $command");
	$curproc->reply_message_nl('command.not_command',
				   "not command, ignored.");
	return 0;
    }

    # 3. Even new comer need to use commands [ guide, subscirbe, confirm ].
    unless ($cred->is_member($curproc, $args)) {
	unless ($config->has_attribute("available_commands_for_stranger",
				       $comname)) {
	    $curproc->reply_message("\n$prompt $command");
	    $curproc->reply_message_nl('command.deny',
				       "not allowed to use this command.");
	    return 0;
	}
	else {
	    Log("permit command $comname for stranger");
	}
    }

    return 1; # o.k. accpet this command.
}


# Descriptions: parse command buffer to make
#               argument vector after command name
#    Arguments: STR($command) STR($comname)
# Side Effects: none
# Return Value: HASH_ARRAY
sub _parse_command_options
{
    my ($command, $comname) = @_;
    my $found = 0;
    my (@options) = ();

    for (split(/\s+/, $command)) {
	push(@options, $_) if $found;
	$found = 1 if $_ eq $comname;
    }

    return \@options;
}


# Descriptions: return command name ( ^\S+ in $command )
#    Arguments: STR($command)
# Side Effects: none
# Return Value: STR
sub _get_command_name
{
    my ($command) = @_;
    my $comname = (split(/\s+/, $command))[0];
    return $comname;
}


# Descriptions: scan message body and execute approviate command
#               with dynamic loading of command definition.
#               It resolves your customized command easily.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: loading FML::Command::command.
#               prepare messages to return.
# Return Value: none
sub _evaluate_command
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    my $argv    = $curproc->command_line_argv();
    my $keyword = $config->{ confirm_keyword };
    my $prompt  = $config->{ command_prompt } || '>>>';

    my $body    = $curproc->{ incoming_message }->{ body }->message_text;
    my @body    = split(/\n/, $body);
    my $id      = $curproc->_pre_scan( \@body );

    $curproc->reply_message("result for your command requests follows:");

  COMMAND:
    for my $command (@body) {
	next if $command =~ /^\s*$/; # ignore empty lines

	# command = line itsetlf, it contains superflous strings
	# comname = command name
	# for example, command = "# help", comname = "help"
	my $comname = _get_command_name($command);

	# validate general command except for confirmation
	unless ($command =~ /$keyword/ && defined($id)) {
	    # we can accpet this command ?
	    my $opts = { comname => $comname, command => $command };
	    unless ($curproc->_can_accpet_command($args, $opts)) {
		# no, we do not accept this command.
		Log("invalid command = $command");
		next COMMAND;
	    }
	}
	# "confirmation" is exceptional.
	else {
	    $comname = $keyword; # comname = confirm
	    Log("try $comname <$command>");
	    $command =~ s/^.*$comname/$comname/;
	}

	# o.k. here we go to execute command
	use FML::Command;
	my $obj = new FML::Command;
	if (defined $obj) {
	    $curproc->reply_message("\n$prompt $command");

	    # arguments to pass off to each method
	    my $command_args = {
		command_mode => 'user',
		comname      => $comname,
		command      => $command,
		ml_name      => $ml_name,
		options      => _parse_command_options($command, $comname),
		argv         => $argv,
		args         => $args,
	    };

	    # execute command ($comname method) under eval().
	    eval q{
		$obj->$comname($curproc, $command_args);
	    };
	    unless ($@) {
		$curproc->reply_message_nl('command.ok', "ok.");
	    }
	    else { # error trap
		$curproc->reply_message_nl('command.fail', "fail.");
		LogError("command ${comname} fail");
		if ($@ =~ /^(.*)\s+at\s+/) {
		    my $reason = $1;
		    Log($reason); # pick up reason
		}
	    }
	}
    } # END OF FOR LOOP: for my $command (@body) { ... }
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
