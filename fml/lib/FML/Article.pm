#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Article;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log);

require Exporter;


# Descriptions: constructor
#    Arguments: $self $curproc
# Side Effects: none
# Return Value: FML::Article object
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _setup_article_template($curproc);
    $me->{ curproc } = $curproc;

    return bless $me, $type;
}


# Descriptions: prepare article template to distribute
#    Arguments: $self $curproc
# Side Effects: build $curproc->{ article }
# Return Value: none
sub _setup_article_template
{
    my ($curproc) = @_;

    # setup article to distribute
    my $msg = $curproc->{'incoming_message'};

    # create an article template by duplicating the incoming message
    $curproc->{ article }->{ header } = $msg->{'header'}->dup();
    $curproc->{ article }->{ body }   = $msg->{'body'};
}


# Descriptions: determine article id (sequence number)
#    Arguments: $self
# Side Effects: record the current article sequence number
# Return Value: number (sequence identifier)
sub increment_id
{
    my ($self) = @_;
    my $curproc  = $self->{ curproc };
    my $config   = $curproc->{ config };
    my $pcb      = $curproc->{ pcb };
    my $seq_file = $config->{ sequence_file };

    use FML::SequenceFile;
    my $sfh = new FML::SequenceFile { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    if ($sfh->error) { Log( $sfh->error ); }

    # save $id in pcb (process control block) and return $id
    $pcb->set('article', 'id', $id);
    $id;
}


sub id
{
    my ($self) = @_;
    my $curproc = $self->{ curproc };    
    my $pcb     = $curproc->{ pcb };
    return $pcb->get('article', 'id');
}


# Descriptions: spool in the article
#    Arguments: $self $curproc
# Side Effects: 
# Return Value: none
sub spool_in
{
    my ($self, $id) = @_;

    # configurations
    my $curproc   = $self->{ curproc };
    my $config    = $curproc->{ config };
    my $spool_dir = $config->{ spool_dir };

    if ( $config->yes( 'use_spool' ) ) {
	unless (-d $spool_dir) {
	    use File::Path;
	    mkpath( $spool_dir, 0, 0700 );
	}

	my $file = $spool_dir . "/" . $id;
	use FileHandle;
	my $fh = new FileHandle;
	$fh->open($file, "w");
	if (defined $fh) {
	    $curproc->{ article }->{ header }->print($fh);
	    print $fh "\n";
	    $curproc->{ article }->{ body }->raw_print($fh);
	    $fh->close;
	    Log("Article $id");
	}
    }
    else {
	Log("not spool article");
    }
}



=head1 NAME

FML::Article - article manipulation components

=head1 SYNOPSIS

... not yet documented ...

=head1 DESCRIPTION

... not yet documented ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Article appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut



1;
