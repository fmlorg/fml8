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


sub DESTROY {}


sub assign
{
    my ($self, $curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $header  = $curproc->{ article }->{ header }; # FML::Header object
    my $subject = $header->get('subject');

    use FML::Header::Subject;

    # if the header carries "Subject: Re: ...", 
    # out ticket system does nothing.
    unless ( FML::Header::Subject->is_reply( $subject ) ) {
	# call SUPER class's FML::Ticket::System::increment_id()
	my $id = $self->increment_id( $config->{ ticket_sequence_file } );

	# O.K. rewrite Subject: of the article to distribute
	unless ($self->error) {
	    $self->pcb_save_id($curproc, $id) if $id;
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


sub _gen_ticket_id
{
    my ($self, $header, $config, $id) = @_;
    my $tag       = $config->{ ticket_subject_tag };
    my $ml_name   = $config->{ ml_name };
    my $ticket_id = sprintf($tag, $ml_name, $id);
    $self->{ _ticket_id } = $ticket_id;
    return $ticket_id;
}


sub _rewrite_subject
{
    my ($self, $header, $config, $id) = @_;

    # create ticket syntax in the subject
    my $ticket_id = $self->_gen_ticket_id($header, $config, $id);

    # append the ticket tag to the subject
    my $subject = $header->get('subject');
    $header->replace('Subject', $subject." ".$ticket_id);

    # X-* information
    $header->add('X-Ticket-ID', $ticket_id);
}


sub _save_ticket_id
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $pcb       = $curproc->{ pcb };

    # initialize $db_dir and $cachefile for further work
    $self->_update_cache_init($curproc, $args) || do { return undef;};

    use IO::File;
    my $fh = new IO::File $self->{ _cachefile }, "a";
    if (defined $fh) {
	my $article_id = $pcb->get('article', 'id');
	my $ticket_id  = $self->{ _ticket_id };
	printf $fh "%-10d %s\n", $article_id, _quote_space( $ticket_id );
	close($fh);
    }
}


sub update_cache
{
    my ($self, $curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $ml_name   = $config->{ ml_name };
    my $db_dir    = $config->{ ticket_db_dir } ."/". $ml_name;
    my $cachefile = $db_dir ."/cache.txt";

    $self->{ _cachefile } = $cachefile;

    $self->_save_ticket_id($curproc, $args);
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
