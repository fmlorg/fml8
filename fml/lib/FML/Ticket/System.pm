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

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub increment_id
{
    my ($self, $seq_file) = @_;

    use FML::SequenceFile;
    my $sfh = new FML::SequenceFile { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    $self->error_reason( $sfh->error );

    $id;
}


sub _pcb_set_id
{
    my ($self, $curproc, $id) = @_;
    my $pcb = $curproc->{ pcb }; # FML::PCB object
    $pcb->set('ticket', 'id', $id);
}


sub _pcb_get_id
{
    my ($self, $curproc) = @_;
    my $pcb = $curproc->{ pcb }; # FML::PCB object
    $pcb->get('ticket', 'id');
}


sub _init_ticket_db_dir
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };

    if (defined $self->{ _db_dir }) {
	my $db_dir    = $self->{ _db_dir };
	unless (-d $db_dir) {
	    use FML::Utils qw(mkdirhier);
	    mkdirhier($db_dir, $config->{ default_directory_mode }) || do {
		$self->error_reason( FML::Utils->error() );
		return undef;
	    };
	}
    }

    return 1;
}


sub _quote_space
{
    my ($id) = @_;
    $id =~ s/\s/_/g;
    return $id;
}


sub _dequote_space
{
    my ($id) = @_;
    $id =~ s/_/ /g;
    return $id;
}


sub AUTOLOAD
{
    my ($self) = @_;
    Log("FYI: unknown method $AUTOLOAD is called");
}


=head1 NAME

FML::Ticket::System - ticket system core engine

=head1 SYNOPSIS

=head1 DESCRIPTION

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
