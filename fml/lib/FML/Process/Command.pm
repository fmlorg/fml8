#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Command.pm,v 1.13 2001/10/10 10:08:06 fukachan Exp $
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

    # $curproc->lock();
    {
	if ($curproc->permit_command($args)) {
	    $curproc->_evaluate_command($args); 
	}
	else {
	    Log("deny command submission");
	}
    }
    # $curproc->unlock();
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


# dynamic loading of command definition.
# It resolves your customized command easily.
sub _evaluate_command
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    my $argv    = $config->{ main_cf }->{ ARGV };
    my $body    = $curproc->{ incoming_message }->{ body }->data_in_body_part;
    my @body    = split(/\n/, $body);
    my $prompt  = $config->{ command_prompt } || '>>>';

    $curproc->reply_message("result for your command requests follows:");

  COMMAND:
    for my $command (@body) { 
	my $comname = (split(/\s+/, $command))[0];
	my $is_valid = 
	    $config->has_attribute( "available_commands", $comname )
		? 'yes' : 'no';
	Log("command = " . $comname . " (valid?=$is_valid)");
	next if $is_valid eq 'no';

	# arguments to pass off to each method
	my @options = ();
	my $optargs = {
	    command_mode => 'user',
	    command      => $command,
	    ml_name      => $ml_name,
	    options      => \@options,
	    argv         => $argv,
	    args         => $args,
	};

	use FML::Command;
	my $obj = new FML::Command;
	if (defined $obj) {
	    $curproc->reply_message("\n$prompt $command");
	    eval q{
		$obj->$comname($curproc, $optargs);
	    };

	    unless ($@) {
		$curproc->reply_message_nl('general.success', "ok.");
	    }
	    else {
		$curproc->reply_message_nl('general.fail', "fail.");
		LogError("command ${comname} fail");
		if ($@ =~ /^(.*)at/) {
		    my $reason = $1;
		    my $nlinfo = $obj->error_nl();

		    if (defined $nlinfo) {
			my $class = $nlinfo->{ class };
			my $args  = $nlinfo->{ args };
			$curproc->reply_message_nl($class, $reason, $args);
		    }
		    else {
			$curproc->reply_message($reason);
		    }
		    Log($reason); # pick up reason
		}
	    }
	}

	#
	# next COMMAND;
	#
    }
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
