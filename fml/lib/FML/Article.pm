#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Article.pm,v 1.33 2002/03/31 02:25:42 fukachan Exp $
#

package FML::Article;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Article - manipulate ML article

=head1 SYNOPSIS

   use FML::Article;
   $article = new FML::Article $curproc;
   $header  = $article->{ header };
   $body    = $article->{ body };

=head1 DESCRIPTION

C<$article> object is just a container which holds
C<header> and C<body> object as hash keys.
The C<header> is an C<FML::Header> object
and
the C<body> is a C<Mail::Message> object.

=head1 METHODS

=head2 C<new(curproc)>

prepare an article message, which is duplicated from the incoming
message $curproc->{ incoming_message }.

=cut


# Descriptions: constructor
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ(FML::Article)
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};

    _setup_article_template($curproc);
    $me->{ curproc } = $curproc;

    return bless $me, $type;
}


# Descriptions: build an article template to distribute
#    Arguments: OBJ($curproc)
# Side Effects: build $curproc->{ article }
# Return Value: none
sub _setup_article_template
{
    my ($curproc) = @_;

    # create an article template by duplicating the incoming message
    my $dupmsg  = $curproc->{'incoming_message'}->{ message }->dup_header;
    if (defined $dupmsg) {
	$curproc->{ article }->{ message } = $dupmsg;
	$curproc->{ article }->{ header }  = $dupmsg->whole_message_header;
	$curproc->{ article }->{ body }    = $dupmsg->whole_message_body;
    }
    else {
	croak("cannot duplicate message");
    }
}


=head2 C<increment_id()>

increment the sequence number of this article C<$self> and
save it to C<$sequence_file>.

This routine uses C<File::Sequence> module.

=cut


# Descriptions: determine article id (sequence number)
#    Arguments: OBJ($self)
# Side Effects: save and update the current article sequence number
# Return Value: NUM(sequence identifier)
sub increment_id
{
    my ($self) = @_;
    my $curproc  = $self->{ curproc };
    my $config   = $curproc->{ config };
    my $pcb      = $curproc->{ pcb };
    my $seq_file = $config->{ sequence_file };

    # XXX we should enhance IO::Adapter module to handle
    # XXX sequential number.
    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    if ($sfh->error) { Log( $sfh->error ); }

    # save $id in pcb (process control block) and return $id
    $pcb->set('article', 'id', $id);
    $id;
}


=head2 C<id()>

return the current article sequence number.

=cut

# Descriptions: return the article id (sequence number)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(sequence number)
sub id
{
    my ($self) = @_;
    my $curproc = $self->{ curproc };
    my $pcb     = $curproc->{ pcb };
    return $pcb->get('article', 'id');
}


=head2 C<spool_in(id)>

save the article to the file name C<id> in the article spool.
If the variable C<$use_spool> is 'yes', this routine works.

=cut


# Descriptions: spool in the article
#    Arguments: OBJ($self) NUM($id)
# Side Effects: create article in ML spool
# Return Value: none
sub spool_in
{
    my ($self, $id) = @_;
    my $curproc   = $self->{ curproc };
    my $config    = $curproc->{ config };
    my $spool_dir = $config->{ spool_dir };

    if ( $config->yes( 'use_spool' ) ) {
	unless (-d $spool_dir) {
	    eval q{
		use File::Path;
		mkpath( $spool_dir, 0, 0700 );
	    };
	    LogError($@) if $@;
	}

	# translate the article path e.g. spool/1900,  spool/2/1900
	my $file = $self->filepath($id);

	use FileHandle;
	my $fh = new FileHandle;
	$fh->open($file, "w");
	if (defined $fh) {
	    $curproc->{ article }->{ header }->print($fh);
	    print $fh "\n";
	    $curproc->{ article }->{ body }->print($fh);
	    $fh->close;
	    Log("Article $id");
	}
    }
    else {
	Log("not spool article");
    }
}


=head2 filepath($id)

return article file path.

=cut


# Descriptions: return article file path.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR(file path)
sub filepath
{
    my ($self, $id) = @_;
    my $curproc   = $self->{ curproc };
    my $config    = $curproc->{ config };
    my $spool_dir = $config->{ spool_dir };

    use Mail::Message::Spool;
    my $spool = new Mail::Message::Spool;
    my $file  = $spool->filepath( {
	base_dir => $spool_dir,
	id       => $id,
    } );

    return $file;
}


=head2 speculate_max_id($spool_dir)

scan the spool_dir and get max number among files in it It must be the
max (latest) article number in its folder.

=cut


# Descriptions: scan the spool_dir and get max number among files in it
#               It must be the max (latest) article number in its folder.
#    Arguments: OBJ($curproc) STR($spool_dir)
# Side Effects: none
# Return Value: NUM(sequence number) or undef
sub speculate_max_id
{
    my ($curproc, $spool_dir) = @_;

    use DirHandle;
    my $dh = new DirHandle $spool_dir;
    if (defined $dh) {
	my $max = 0;
	my $fn  = ''; # file name

	while (defined($fn = $dh->read)) {
	    next unless $fn =~ /^\d+$/;
	    $max = $max < $fn ? $fn : $max;
	}
	$dh->close();

	return( $max > 0 ? $max : undef );
    }

    return undef;
}


=head1 SEE ALSO

L<FML::Header>,
L<MailingList::Messsages>,
L<File::Sequence>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
