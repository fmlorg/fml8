#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Command.pm,v 1.16 2001/10/12 00:19:19 fukachan Exp $
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

FML::Process::Command -- fml5 command dispacher.

=head1 SYNOPSIS

   use FML::Process::Command;
   ...

See L<FML::Process::Flow> for details of fml process flow.

=head1 DESCRIPTION

C<FML::Process::Command> is a command wrapper and top level
dispatcher for commands.
It kicks off corresponding 
C<FML::Command>->C<$command($curproc,$args)> 
for the given C<$command>.

=head1 METHODS

=head2 C<new($args)>

make fml process object.

    my $curproc = new FML::Process::Kernel $args;

=head2 C<prepare($args)>

forward the request to SUPER CLASS.

=cut


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


sub prepare
{
    my ($self, $args) = @_;
    $self->SUPER::prepare($args);
}


=head2 C<verify_request($args)>

verify the sender is a valid member or not.

=cut

sub verify_request
{
    my ($curproc, $args) = @_;
    $curproc->verify_sender_credential();
}


=head2 C<run($args)>

dispatcher to run correspondig C<FML::Command::command> for
C<command>.

    lock
    execute FML::Command::command
    unlock

=cut

sub run
{
    my ($curproc, $args) = @_;
    $curproc->_evaluate_command($args); 
}


=head2 C<finish($args)>

    $curproc->inform_reply_messages();

=cut

sub finish
{
    my ($curproc, $args) = @_;

    $curproc->inform_reply_messages();
    $curproc->queue_flush();
}


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


# dynamic loading of command definition.
# It resolves your customized command easily.
sub _evaluate_command
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $cred    = $curproc->{ credential }; # user credential

    my $ml_name = $config->{ ml_name };
    my $argv    = $config->{ main_cf }->{ ARGV };
    my $keyword = $config->{ confirm_keyword };
    my $body    = $curproc->{ incoming_message }->{ body }->data_in_body_part;
    my @body    = split(/\n/, $body);
    my $prompt  = $config->{ command_prompt } || '>>>';
    my $id      = $curproc->_pre_scan( \@body );

    $curproc->reply_message("result for your command requests follows:");

  COMMAND:
    for my $command (@body) {
	next if $command =~ /^\s*$/; # ignore empty lines

	my $comname = (split(/\s+/, $command))[0];
	my $opts    = { comname => $comname, command => $command, };

	# special treating for confirmation
	unless ($command =~ /$keyword/ && defined($id)) {
	    # we can accpet this command ?
	    unless ($curproc->_can_accpet_command($args, $opts)) {
		# no, we do not accept this command. 
		Log("invalud command = $command");
		next COMMAND;
	    }
	}
	else {
	    $comname = $keyword; # comname = confirm
	    Log("try $comname <$command>");
	    $command =~ s/^.*$comname/$comname/;
	}

	# o.k. here we go to execute command
	use FML::Command;
	my $obj = new FML::Command;
	if (defined $obj) {
	    # arguments to pass off to each method
	    my $optargs = {
		command_mode => 'user',
		command      => $command,
		ml_name      => $ml_name,
		options      => [],
		argv         => $argv,
		args         => $args,
	    };

	    $curproc->reply_message("\n$prompt $command");
	    eval q{
		$obj->$comname($curproc, $optargs);
	    };
	    unless ($@) {
		$curproc->reply_message_nl('command.ok', "ok.");
	    }
	    else {
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

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Command appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
