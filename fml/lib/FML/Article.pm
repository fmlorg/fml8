#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Article.pm,v 1.50 2002/12/15 14:02:08 fukachan Exp $
#

package FML::Article;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Article - manipulate an ML article and related information

=head1 SYNOPSIS

    use FML::Article;
    $article = new FML::Article $curproc;

    # get sequence number
    my $id = $article->increment_id;

    # spool in the article before delivery
    $article->spool_in($id);

    my $article_file = $article->filepath($article_id);

=head1 DESCRIPTION

C<$article> object is just a container which holds
C<header> and C<body> object as hash keys.
The C<header> is an C<FML::Header> object,
the C<body> is a C<Mail::Message> object
and
the C<message> is the head object of object chains.

C<new()> method sets up the $curproc as

    my $dupmsg  = $curproc->{ 'incoming_message' }->{ message }->dup_header;
    $curproc->{ article }->{ message } = $dupmsg;
    $curproc->{ article }->{ header }  = $dupmsg->whole_message_header;
    $curproc->{ article }->{ body }    = $dupmsg->whole_message_body;

This is the basic structure of the article object.

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

    if (defined $curproc->{ 'incoming_message' }->{ message }) {
	_setup_article_template($curproc);
    }
    $me->{ curproc } = $curproc;

    return bless $me, $type;
}


# Descriptions: build an article template to distribute.
#    Arguments: OBJ($curproc)
# Side Effects: build $curproc->{ article } HASH_REF.
# Return Value: none
sub _setup_article_template
{
    my ($curproc) = @_;

    # create an article template by duplicating the incoming message
    my $msg_in = $curproc->{ 'incoming_message' }->{ message };
    my $duphdr = $msg_in->dup_header;
    if (defined $duphdr) {
	$curproc->{ article }->{ message } = $duphdr;
	$curproc->{ article }->{ header }  = $duphdr->whole_message_header;
	$curproc->{ article }->{ body }    = $duphdr->whole_message_body;
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
    my $config   = $curproc->config();
    my $pcb      = $curproc->pcb();
    my $seq_file = $config->{ sequence_file };

    # XXX-TODO we should enhance IO::Adapter module to handle
    # XXX-TODO sequential number.
    use File::Sequence;
    my $sfh = new File::Sequence { sequence_file => $seq_file };
    my $id  = $sfh->increment_id;
    if ($sfh->error) { LogError( $sfh->error ); }

    # save $id in pcb (process control block) and return $id
    $pcb->set('article', 'id', $id);

    return $id;
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
    my $curproc  = $self->{ curproc };
    my $config   = $curproc->config();
    my $pcb      = $curproc->pcb();

    my $n = $pcb->get('article', 'id');

    # within Process::Distribute
    if ($n) {
	return $n;
    }
    # processes not Process::Distribute
    else {
	my $seq_file = $config->{ sequence_file };

	use File::Sequence;
	my $sfh = new File::Sequence { sequence_file => $seq_file };
	my $n   = $sfh->get_id();
	$sfh->close();

	return $n;
    }
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
    my $curproc    = $self->{ curproc };
    my $config     = $curproc->config();
    my $spool_dir  = $config->{ spool_dir };
    my $use_subdir = $config->{ spool_type } eq 'subdir' ? 1 : 0;

    if ( $config->yes( 'use_spool' ) ) {
	unless (-d $spool_dir) {
	    $curproc->mkdir($spool_dir, "mode=private");
	}

	# translate the article path e.g. spool/1900,  spool/2/1900
	my $file = $self->filepath($id);

	unless (-f $file) {
	    use FileHandle;
	    my $fh = new FileHandle;
	    if (defined $fh) {
		$fh->open($file, "w");
		$curproc->{ article }->{ header }->print($fh);
		print $fh "\n";
		$curproc->{ article }->{ body }->print($fh);
		$fh->close;
		Log("article $id");
	    }
	}
	else {
	    LogError("$id article already exists");
	}
    }
    else {
	Log("not spool article $id");
    }
}


=head2 filepath($id)

return article file path.

=head2 subdirpath($id)

return subdir path.

=cut


# Descriptions: return article file path.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR(file path)
sub filepath
{
    my ($self, $id) = @_;
    my ($file_path, $dir_path) = $self->_filepath($id);
    return $file_path;
}


# Descriptions: return subdir path for this article.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR(file path)
sub subdirpath
{
    my ($self, $id) = @_;
    my ($file_path, $dir_path) = $self->_filepath($id);
    return $dir_path;
}


# Descriptions: return article file and dir path.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: ARRAY( STR(file path), STR(dir path) )
sub _filepath
{
    my ($self, $id) = @_;
    my $curproc    = $self->{ curproc };
    my $config     = $curproc->config();
    my $spool_dir  = $config->{ spool_dir };
    my $use_subdir = $config->{ spool_type } eq 'subdir' ? 1 : 0;
    my $unit       = $config->{ spool_subdir_unit };

    use Mail::Message::Spool;
    my $spool = new Mail::Message::Spool;
    my $args  = {
	base_dir    => $spool_dir,
	id          => $id,
	use_subdir  => $use_subdir,
	subdir_unit => $unit,
    } ;
    my $file = $spool->filepath($args);
    my $dir  = $spool->dirpath($args);

    unless (-d $dir) {
	$curproc->mkdir($dir, "mode=private");
    }

    return ($file, $dir);
}


=head2 speculate_max_id([$spool_dir])

scan the spool_dir and get the max number among files in it. It must
be the max (latest) article number in its folder.

=cut


# Descriptions: scan the spool_dir and get max number among files in it.
#               It must be the max (latest) article number in its folder.
#    Arguments: OBJ($curproc) STR($spool_dir)
# Side Effects: none
# Return Value: NUM(sequence number) or undef
sub speculate_max_id
{
    my ($curproc, $spool_dir) = @_;
    my $config     = $curproc->config();
    my $use_subdir = $config->{ spool_type } eq 'subdir' ? 1 : 0;

    unless (defined $spool_dir) {
	$spool_dir = $config->{ spool_dir };
    }

    Log("max_id: (debug) scan $spool_dir subdir=$use_subdir");

    if ($use_subdir) {
	use DirHandle;
	my $dh = new DirHandle $spool_dir;

	if (defined $dh) {
	    my $fn         = ''; # file name
	    my $subdir     = '';
	    my $max_subdir = 0;

	  ENTRY:
	    while (defined($fn = $dh->read)) {
		next ENTRY unless $fn =~ /^\d+$/;

		use File::Spec;
		$subdir = File::Spec->catfile($spool_dir, $fn);

		if (-d $subdir) {
		    my $max_subdir = $max_subdir > $fn ? $max_subdir : $fn;
		}
	    }

	    $dh->close();

	    # XXX-TODO wrong? to speculate max_id in subdir spool?
	    $subdir = File::Spec->catfile($spool_dir, $max_subdir);
	    Log("max_id: (debug) scan $subdir");
	    $curproc->speculate_max_id($subdir);
	}
    }

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
L<Mail::Message>,
L<File::Sequence>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
