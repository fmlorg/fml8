#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Article.pm,v 1.60 2004/01/01 23:52:07 fukachan Exp $
#

package FML::Article;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use FML::Log qw(Log LogWarn LogError);

use FML::Article::Sequence;
@ISA = qw(FML::Article::Sequence);


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
C<header> and C<body> objects as hash keys.
The C<header> is an C<FML::Header> object,
the C<body> is a C<Mail::Message> object
and
the C<message> is the head object of message object chains.

C<new()> method sets up the $curproc as

    my $dupmsg  = $curproc->{ 'incoming_message' }->{ message }->dup_header;
    $curproc->{ article }->{ message } = $dupmsg;
    $curproc->{ article }->{ header }  = $dupmsg->whole_message_header;
    $curproc->{ article }->{ body }    = $dupmsg->whole_message_body;

This is the basic structure of the article object.

=head1 METHODS

=head2 new(curproc)

prepare an article message, which is duplicated from the incoming
message $curproc->{ incoming_message }.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ(FML::Article)
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    my $msg    = $curproc->incoming_message();

    if (defined $msg) {
	_setup_article_template($curproc, $msg);
    }

    return bless $me, $type;
}


# Descriptions: return lock channel name.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_lock_channel_name
{
    my ($self) = @_;

    # XXX LOCK_CHANNEL: article_spool
    return 'article_spool';
}


# Descriptions: build an article template to distribute.
#    Arguments: OBJ($curproc) OBJ($msg_in)
# Side Effects: build $curproc->{ article } HASH_REF.
# Return Value: none
sub _setup_article_template
{
    my ($curproc, $msg_in) = @_;

    # create an article template by duplicating the incoming message
    my $duphdr = $msg_in->dup_header;
    if (defined $duphdr) {
	# here, we handle raw $curproc to build $curproc->{ article } ...
	$curproc->{ article }->{ message } = $duphdr;
	$curproc->{ article }->{ header }  = $duphdr->whole_message_header;
	$curproc->{ article }->{ body }    = $duphdr->whole_message_body;
    }
    else {
	croak("cannot duplicate message");
    }
}


=head2 spool_in($id)

save the article to the file name C<$id> in the article spool.
If the variable C<$use_spool> is 'yes', this routine works.

=cut


# Descriptions: spool in the article
#    Arguments: OBJ($self) NUM($id)
# Side Effects: create article in ML spool
# Return Value: none
sub spool_in
{
    my ($self, $id) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();
    my $spool_dir   = $config->{ spool_dir };
    my $use_subdir  = $config->{ spool_type } eq 'subdir' ? 1 : 0;
    my $channel     = $self->get_lock_channel_name();

    # XXX-TODO: use_spool -> use_article_spool ?
    if ($config->yes( 'use_spool' )) {
	$curproc->lock($channel);

	unless (-d $spool_dir) {
	    $curproc->mkdir($spool_dir, "mode=private");
	}

	# translate the article path e.g. spool/1900,  spool/2/1900
	my $file = $self->filepath($id);

	# verify and create subdir if not found before spool in.
	if ($use_subdir) {
	    my $dir = $self->subdirpath($id);
	    unless (-d $dir) {
		$curproc->mkdir($dir, "mode=private");
	    }
	}

	unless (-f $file) {
	    use FileHandle;
	    my $fh = new FileHandle;
	    if (defined $fh) {
		$fh->open($file, "w");
		$curproc->{ article }->{ header }->print($fh);
		print $fh "\n";
		$curproc->{ article }->{ body }->print($fh);
		$fh->close;
		$curproc->log("article $id");
	    }
	}
	else {
	    $curproc->logerror("$id article already exists");
	}

	$curproc->unlock($channel);
    }
    else {
	$curproc->log("not spool article $id");
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
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();
    my $spool_dir   = $config->{ spool_dir };
    my $use_subdir  = $config->{ spool_type } eq 'subdir' ? 1 : 0;
    my $unit        = $config->{ spool_subdir_unit };

    use Mail::Message::Spool;
    my $spool    = new Mail::Message::Spool;
    my $mms_args = {
	base_dir    => $spool_dir,
	id          => $id,
	use_subdir  => $use_subdir,
	subdir_unit => $unit,
    } ;
    my $file = $spool->filepath($mms_args);
    my $dir  = $spool->dirpath($mms_args); # spool/ or spool/$subdir/

    return ($file, $dir);
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

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
