#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: TicketSystem.pm,v 1.14 2001/04/03 09:45:44 fukachan Exp $
#

package FML::Process::TicketSystem;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::TicketSystem -- primitive fml5 ticket system

=head1 SYNOPSIS

    use FML::Process::TicketSystem;
         ... snip ...

    use FML::Ticket::Model::toymodel;
    $ticket = FML::Ticket::Model::toymodel->new($curproc, $args);
    $ticket->$method($curproc, $args);

=head1 DESCRIPTION

This class drives ticket system in the top level.
The ticket database is maintained by each ticket system model, 
which is called in C<run()> method.

=head1 METHOD

=head2 C<new($args)>

create a C<FML::Process::Kernel> object and return it.

=head2 C<prepare()>

dummy.

=cut


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


# Descriptions: dummy to avoid to take data from STDIN 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub prepare
{
    ;
}


=head2 C<run($args)>

call the actual ticket system.
It supports only 'list' and 'close' commands.

=cut

sub run
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $model   = $config->{ ticket_model };
    my $pkg     = "FML::Ticket::Model::". $model;
    my $argv    = $args->{ ARGV };
    my $command = $argv->[ 0 ] || 'list';

    # fake "use FML::Ticket::Model::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $ticket = $pkg->new($curproc, $args);
	$ticket->mode( { mode => 'text' } );

	if ($command eq 'list') {
	    $ticket->show_summary($curproc, $args);
	}
	elsif ($command eq 'close') {
	    $curproc->lock();

	    my $ticket_id = $argv->[ 2 ];
	    my $args = {
		ticket_id => $ticket_id, 
		status    => 'close',
	    };
	    if ($ticket_id) {
		$ticket->set_status($curproc, $args);
	    }
	    else {
		croak("specify \$ticket_id");
	    }

	    $curproc->unlock();
	}
	else {
	    croak("unknown command=$command\n");
	}
    }
    else {
	Log($@);
    }
}


sub DESTROY {}

# Descriptions: dummy routine to avoid errors
#               since we need all methods defined in FML::Process::Flow.
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub AUTOLOAD
{
    my ($curproc, $args) = @_;
    1;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
