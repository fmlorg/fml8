#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
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

FML::Process::Command -- fml5 command wrapper.

=head1 SYNOPSIS

   use FML::Process::Command;
   ...

See L<FML::Process::Flow> for details of flow.

=head1 DESCRIPTION

C<FML::Process::Command> is a command wrapper and top level
dispatcher.
It kicks off C<FML::Command>->C<$command($curproc, $args)> for each
C<$command>.

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


sub verify_request
{
    my ($curproc, $args) = @_;
    $curproc->verify_sender_credential();
}


sub run
{
    my ($curproc, $args) = @_;

    $curproc->lock();
    {
	# user credential
	my $cred = $curproc->{ credential };

	# Q: the mail sender is a ML member?
	if ($cred->is_member) {
	    $curproc->_evaluate_command($args); 
	}
    }
    $curproc->unlock();
}


sub finish
{
    my ($curproc, $args) = @_;

    $curproc->inform_reply_messages();
}


# dynamic loading of command definition.
# It resolves your customized command easily.
sub _evaluate_command
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $ml_name = $config->{ ml_name };
    my $argv    = $config->{ main_cf }->{ ARGV };
    my $body    = $curproc->{ incoming_message }->{ body }->get_content_body;
    my @body    = split(/\n/, $body);

    for my $command (@body) { 
	my $is_valid = 
	    $config->has_attribute( "available_commands", $command )
		? 'yes' : 'no';
	Log("command = " . $command . " (valid?=$is_valid)");
	next if $is_valid eq 'no';

	# arguments to pass off to each method
	my $optargs = {
	    command => $command,
	    ml_name => $ml_name,
	    argv    => $argv,
	    args    => $args,
	};

	my $pkg = 'FML::Command';
	eval qq{ require $pkg; $pkg->import();};
	unless ($@) {
	    my $obj = new $pkg;
	    $obj->$command($curproc, $optargs);
	}
	else { 
	    Log($@);
	}
    }
}


1;
