#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

package FML::Process::TicketSystem;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log);
use FML::Config;

require Exporter;
@ISA = qw(FML::Process::Kernel Exporter);


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# dummy
sub prepare
{
    ;
}


sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $model   = $config->{ ticket_model };
    my $pkg     = "FML::Ticket::Model::". $model;
    my $argv    = $args->{ ARGV };
    my $command = $argv->[ 0 ];

    # fake use() to do "use FML::Ticket::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	$curproc->lock();

	if ($command eq 'list') {
	    $curproc->_ticket_show_summary($args, $pkg);
	}
	else {
	    croak("unknown command=$command\n");
	}

	$curproc->unlock();
    }
    else {
	Log($@);
    }
}


sub _ticket_show_summary
{
    my ($curproc, $args, $pkg) = @_;
    my $ticket = $pkg->new($curproc, $args);
    $ticket->show_summary($curproc, $args);
}


sub AUTOLOAD
{
    my ($curproc, $args) = @_;
    ;
}


=head1 NAME

TicketSystem -- primitive fml5 ticket system

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

1;
