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
    bless $me, $type;

    $me->_setup_article_template($curproc);
    $me->{ curproc } = $curproc;

    return $me;
}


# Descriptions: prepare article template to distribute
#    Arguments: $self $curproc
# Side Effects: build $curproc->{ article }
# Return Value: none
sub _setup_article_template
{
    my ($self, $curproc) = @_;

    # setup article to distribute
    my $msg = $curproc->{'incoming_mail'};

    # create an article template by duplicating the incoming message
    $curproc->{ article }->{ header } = $msg->{'header'}->dup();
    $curproc->{ article }->{ body }   = $msg->{'body'};
    
    # initialize the header object
    use FML::Header;
    $curproc->{'article'}->{'header'}->check;
    $curproc->{'article'}->{'header'}->rewrite;
}


# Descriptions: determine article id (sequence number)
#    Arguments: $self
# Side Effects: record the current article sequence number
# Return Value: number (sequence identifier)
sub gen_article_id
{
    my ($self) = @_;
    my $curproc   = $self->{ curproc };
    my $config    = $curproc->{ config };
    my $seq_file  = $config->{ sequence_file };
    my $id        = 0;

    use IO::File::Atomic;
    my ($rh, $wh) = IO::File::Atomic->rw_open($seq_file);

    # read the current sequence number
    if (defined $rh) {
	$id = $rh->getline;
	$rh->close;
    }

    # increment $id. The incremented number is the current article ID.
    $id++;

    # save $id
    print $wh $id, "\n";
    $wh->close;

    # return value
    $curproc->{ pcb }->{ article_id } = $id;
    $id;
}


sub id
{
    my ($self) = @_;
    my $curproc = $self->{ curproc };    
    return $curproc->{ pcb }->{ article_id };
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

    print "yes: ",  $config->yes( 'use_spool' ) , "\n";

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
	    print $fh ${ $curproc->{ article }->{ body } };
	    $fh->close;
	}
    }
    else {
	Log("not spool");
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

FML::Article.pm appeared in fml5.

=cut



1;
