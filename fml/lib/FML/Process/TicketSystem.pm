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
    my $pkg    = "FML::Ticket::Model::";

    if ($model eq 'toymodel') {
	$pkg .= $model;
    }
    else {
	Log("ticket: unknown model");
	return;
    }

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

distribute -- fml5 article distributer program.

=head1 SYNOPSIS

   distribute [-d] config.cf

=head1 DESCRIPTION

libexec/fml.pl, the wrapper, executes this program. For example, The
incoming mail to elena@fml.org kicks off libexec/distribute via
libexec/fml.pl, whereas mail to elena-ctl@fml.org kicks off
libexec/command finally.

   incoming_mail =>
      elena@fml.org       => fml.pl => libexec/distribute
      elena-ctl@fml.org   => fml.pl => libexec/command
      elena-admin@fml.org => forwarded to administrator(s)
                                  OR
                          => libexec/mead

C<-d>
    debug on.

=head1 FLOW AROUND COMPONENTS

   |  <=> FML::BaseSystem
   |      load configuration files
   |      start logging service
   |
   |  STDIN                     => FML::Parse
   |  $CurProc->{'incoming_mail'} <=
   |  $CurProc->{'credential'}
   | 
   |  (lock)
   |  prepare article
   |  $CurProc->{'article'} is spooled in.
   |  $CurProc->{'article'}    <=> Service::SMTP
   |  (unlock)
   V

=cut

1;
