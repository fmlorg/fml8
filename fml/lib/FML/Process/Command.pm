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
use FML::Log qw(Log);
use FML::Config;

=head1 NAME

FML::Process::Command -- fml5 command processor.

=head1 SYNOPSIS

   use FML::Process::Command;
   ...

See L<FML::Process::Flow> for details of flow.

=head1 DESCRIPTION

=cut


require Exporter;
@ISA = qw(FML::Process::Kernel Exporter);


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
	    _evaluate_command( $curproc ); 
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
    my ( $curproc ) = @_;
    my $config = $curproc->{ config };
    my $body   = $curproc->{ incoming_message }->{ body }->get_content_body;
    my @body   = split(/\n/, $body);

    for my $command (@body) { 
	my $is_valid = 
	    $config->has_attribute( "available_commands", $command )
		? 'yes' : 'no';
	Log("command = " . $command . " (valid?=$is_valid)");
	next if $is_valid eq 'no';
	eval qq{ require FML::Command::$command; };
	if ($@) { Log($@);}
    }
}


1;
