#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Ticket::System;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Errors qw(error_reason error error_reset);
use FML::Log qw(Log);


=head1 NAME

FML::Ticket::System - ticket system core engine

=head1  SYNOPSIS

   use Ticket::Model::toymodel;
   $ticket = new Ticket::Model::toymodel;
   $ticket->assign($curproc, $args);
   $ticket->update_cache($curproc, $args);

=head1 DESCRIPTION

the base class of ticket systems.
This module provides basic functions to help sub classes.

=head2 CLASS HIERARCHY

        FML::Ticket::System
                |
                A 
       -------------------
       |        |        |
       A        A        A
    toymodel  model2    ....

=head1 METHODS

=head2 C<new()>

the usual constructor.

=cut


# Descriptions: constructor
#    Arguments: $self
# Side Effects: none
# Return Value: object
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: save the ticket $id in FML::PCB object
#    Arguments: $self $curproc $id
# Side Effects: set id in PCB
# Return Value: none
sub _pcb_set_id
{
    my ($self, $curproc, $id) = @_;
    my $pcb = $curproc->{ pcb }; # FML::PCB object
    $pcb->set('ticket', 'id', $id);
}


# Descriptions: get the ticket $id from FML::PCB
#    Arguments: $self $curproc
# Side Effects: none
# Return Value: number (ticket id)
sub _pcb_get_id
{
    my ($self, $curproc) = @_;
    my $pcb = $curproc->{ pcb }; # FML::PCB object
    $pcb->get('ticket', 'id');
}


# Descriptions: set up directory which is taken from 
#               $self->{ _db_dir }
#    Arguments: $self $curproc $args
# Side Effects: create a "_db_dir" directory if needed
# Return Value: 1 (success) or undef (fail)
sub _init_ticket_db_dir
{
    my ($self, $curproc, $args) = @_;
    my $config = $curproc->{ config };

    if (defined $self->{ _db_dir }) {
	my $db_dir    = $self->{ _db_dir };
	unless (-d $db_dir) {
	    use File::Utils qw(mkdirhier);
	    mkdirhier($db_dir, $config->{ default_directory_mode }) || do {
		$self->error_reason( File::Utils->error() );
		return undef;
	    };
	}
    }

    return 1;
}


# Descriptions: replace SPACE with _
#    Arguments: string
# Side Effects: none
# Return Value: string
sub _quote_space
{
    my ($id) = @_;
    $id =~ s/\s/_/g;
    return $id;
}


# Descriptions: replace _ with SPACE
#    Arguments: string
# Side Effects: none
# Return Value: string
sub _dequote_space
{
    my ($id) = @_;
    $id =~ s/_/ /g;
    return $id;
}


# Descriptions: log the error "undefined function" for debug
#               XXX nuke this in the future ! this is only for debug.
#    Arguments: $self
# Side Effects: log the error
# Return Value: none
sub AUTOLOAD
{
    my ($self) = @_;
    Log("FYI: unknown method $AUTOLOAD is called");
}


=head2 C<increment_id(file)>

increment sequence number which is taken up from C<file> 
and save its new number to C<file>.

=cut


# Descriptions: increment $id holded in $seq_file
#    Arguments: $self $seq_file
# Side Effects: increment id holded in $seq_file 
# Return Value: number
sub increment_id
{
    my ($self, $seq_file) = @_;

    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    $self->error_reason( $sfh->error );

    $id;
}


=head1 REFERENCES

=head2 ticket status ("RT" case)
                
A Request will always be in one of the following four states:

     Open -- the Request is expecting imminent action a/o updates
  Stalled -- the Request needs a specific action or piece of
             information before it can proceed
 Resolved -- the Request has either been answered or successfully
             taken care of, and no longer needs action
     Dead -- the request should not have been in the ticketing system to begin
             with and has been completely purged.

=head2 ticket status ("REQ" case)

       Another somewhat hardcoded features is the "status" field.
       We're not exactly sure how to use this yet,  but  normally
       use  "stalled" to indicate that this request isn't one can
       make any progress at the moment, thus isn't worth  picking
       from the queue to work on.


=head1 SEE ALSO

L<File::Utils>,
L<File::Sequence>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Ticket::System appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
