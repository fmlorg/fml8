#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Ticket::Model::toymodel;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log);
use FML::Ticket::System;

require Exporter;
@ISA = qw(FML::Ticket::System Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub add_ticket
{
    my ($self, $header, $config, $args) = @_;
    my $subject = $header->get('subject');

    use FML::Header::Subject;

    # if the header carries "Subject: Re: ...", 
    # out ticket system does nothing.
    unless ( FML::Header::Subject->is_reply( $subject ) ) {
	# call SUPER class's FML::Ticket::System::increment_id()
	my $id = $self->increment_id( $config->{ ticket_sequence_file } );
	unless ($self->error) {
	    $self->_rewrite_subject($header, $config, $id);
	}
	else {
	    Log( $self->error ); 
	};
    }
    else {
	Log("ticket: not looks reply message, so ignored");
    }
}


sub _rewrite_subject
{
    my ($self, $header, $config, $id) = @_;

    my $ml_name = $config->{ ml_name };
    my $tag     = $config->{ ticket_subject_tag };
    my $subject = $header->get('subject');
    my $ticket_id = sprintf($tag, $ml_name, $id );

    # append the ticket tag
    $header->replace('subject', $subject." ".$ticket_id);
}



=head1 NAME

FML::__HERE_IS_YOUR_MODULE_NAME__.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASS HIERARCHY

        FML::Ticket::System
                |
                A 
       -------------------
       |        |        |
    toymodel  model2    ....

=head1 METHOD

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut


1;
