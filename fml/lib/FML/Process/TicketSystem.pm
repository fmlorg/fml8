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

    # use Data::Dumper; print Dumper( $args ); sleep 30;

    $curproc->lock();
    {
	$curproc->_ticket_list_up($args);
    }
    $curproc->unlock();
}


sub _ticket_list_up
{
    my ($curproc, $args) = @_;    
    my $config = $curproc->{ config };
    my $model  = $config->{ ticket_model };
    my $pkg    = "FML::Ticket::Model::". $model;

    # fake use() to do "use FML::Ticket::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $ticket = $pkg->new($curproc, $args);
	$ticket->list_up($curproc, $args);
    }
    else {
	Log($@);
    }
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
