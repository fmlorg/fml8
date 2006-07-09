#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Article.pm,v 1.79 2006/05/04 05:33:48 fukachan Exp $
#

package FML::Article;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK
	    $global_threshold_mtime @global_too_old_article_list);
use Carp;

use FML::Article::Sequence;
@ISA = qw(FML::Article::Sequence);


=head1 NAME

FML::Article - manipulate an ML article and related information.

=head1 SYNOPSIS

    use FML::Article;
    my $article = new FML::Article $curproc;

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
which is the head object of a message object chain.

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
	unless (defined $curproc->{ article }->{ message }) {
	    _setup_article_template($curproc, $msg);
	}
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

    # already defined.
    return if defined $curproc->{ article }->{ message };

    # create an article template by duplicating the incoming message
    my $duphdr = $msg_in->dup_header;
    if (defined $duphdr) {
	# here, we handle raw $curproc to build $curproc->{ article } ...
	$curproc->{ article }->{ message } = $duphdr; # head of a chain.
	$curproc->{ article }->{ header }  = $duphdr->whole_message_header;
	$curproc->{ article }->{ body }    = $duphdr->whole_message_body;
    }
    else {
	$curproc->logerror("cannot duplicate message");
	croak("cannot duplicate message");
    }
}


=head2 spool_in($id)

save the article to the file name C<$id> in the article spool.
If the variable C<$use_article_spool> is 'yes', this routine works.

=cut


# Descriptions: spool in the article specified by $id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: create article in ML spool
# Return Value: none
sub spool_in
{
    my ($self, $id) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();

    if ($config->yes('use_article_spool')) {
	my $spool_dir  = $config->{ spool_dir };
	my $use_subdir = $config->{ spool_type } eq 'subdir' ? 1 : 0;
	my $channel    = $self->get_lock_channel_name();

	$curproc->lock($channel);

	unless (-d $spool_dir) {
	    $curproc->mkdir($spool_dir, "mode=private");
	}

	# translate id to the article path e.g. spool/1900, spool/2/1900.
	my $file = $self->filepath($id);

	# verify and create subdir if not found before spooling in.
	if ($use_subdir) {
	    my $dir = $self->subdirpath($id);
	    unless (-d $dir) {
		$curproc->mkdir($dir, "mode=private");
	    }
	}

	unless (-f $file) {
	    my $error = 0;

	    # XXX-TODO: IO::Adapter::AtomicFile
	    use FileHandle;
	    my $fh = new FileHandle;
	    if (defined $fh) {
	        $fh->autoflush(1);
		$fh->open($file, "w");

		my $header = $curproc->article_message_header();
		my $body   = $curproc->article_message_body();

		$fh->clearerr();
		$header->print($fh);
		$error++ if $fh->error();

		print $fh "\n";

		$fh->clearerr();
		$body->print($fh);
		$error++ if $fh->error();

		if ($error) {
		    $fh->close;
		    $curproc->logerror("failed to create article");
		    $self->_try_failover($curproc, $id, $file);
		}
		else {
		    $fh->close;
		    $curproc->log("article $id");

		    # update article message id cache.
		    my $_header = $curproc->incoming_message_header();
		    $_header->update_article_message_id_cache($config);
		}
	    }
	}
	else {
	    $curproc->logerror("$id article already exists");
	}

	$curproc->unlock($channel);
    }
    else {
	$curproc->log("article: spooling disabled");
    }
}


# Descriptions: When we fail to create an article file,
#               we try to save the original message at least.
#               So, we try to save article content from incoming queue.
#    Arguments: OBJ($self) OBJ($curproc) NUM($id) STR($article_file)
# Side Effects: link(2) or rename(2).
# Return Value: none
sub _try_failover
{
    my ($self, $curproc, $id, $article_file) = @_;
    my $queue_file = $curproc->incoming_message_get_cache_file_path();

    # 0. nuke (must be) broken article file.
    if (-f $article_file) { unlink $article_file;}

    # 1. try link(2).
    if (link($queue_file, $article_file)) {
	$curproc->logwarn("article: linked queue to article file");
	$curproc->log("article $id (faked)");
    }
    # 2. try rename(2).
    elsif (rename($queue_file, $article_file)) {
	$curproc->logwarn("article: renamed queue to article file");
	$curproc->log("article $id (faked)");
    }
    else {
	$curproc->logerror("article: give up failover.");
    }
}


=head2 prepend($data)

prepend the message into the article object.

=head2 append($data)

append the message into the article object.

=cut


# Descriptions: prepend the message into the article object.
#    Arguments: OBJ($self) HASH_REF($data)
# Side Effects: update article object.
# Return Value: none
sub prepend
{
    my ($self, $data) = @_;
    my $curproc = $self->{ _curproc };
    my $body    = $curproc->article_message_body();
    my $head    = $body->whole_message_body_head();
    $head->prepend($data);
}


# Descriptions: append the message into the article object.
#    Arguments: OBJ($self) HASH_REF($data)
# Side Effects: update article object.
# Return Value: none
sub append
{
    my ($self, $data) = @_;
    my $curproc = $self->{ _curproc };
    my $body    = $curproc->article_message_body();
    my $tail    = $body->whole_message_body_tail();
    $tail->append($data);
}


# Descriptions: add thread outline to article header or/and body.
#    Arguments: OBJ($self) HASH_REF($tdb_args)
# Side Effects: none
# Return Value: none
sub add_outline
{
    my ($self, $tdb_args) = @_;
    my $curproc = $self->{ _curproc };

    use FML::Article::Outline;
    my $outline = new FML::Article::Outline $curproc;
    $outline->add_outline($tdb_args);
}


=head1 EXPIRE ARTICLES

=head2 expire()

expire too old articles.

=cut


# Descriptions: expire too old articles.
#    Arguments: OBJ($self)
# Side Effects: too old article are removed.
# Return Value: none
sub expire
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    unless ($config->yes('use_article_expire')) {
	$curproc->logdebug("article expiration disabled");
	return;
    }

    # 1. find too old articles by checking mtime of each article.
    my $spool_dir     = $config->{ spool_dir };
    my $how_old       = $config->as_second("article_expire_limit");
    my $threshold     = time - $how_old;
    my $too_old_files = $self->_find_too_old_articles($spool_dir, $threshold);

    # 2. expire old articles.
    use File::Basename;
    for my $article (@$too_old_files) {
	if (-f $article) {
	    unlink($article);

	    my $id = basename($article);
	    unless (-f $article) {
		$curproc->log("expire: article $id removed");
	    }
	    else {
		$curproc->logerror("expire: removal of article $id fail");
	    }
	}
    }

    # 3. expire article summary.
    # XXX-TODO: who ensure @$too_old_files is sorted already ???
    # XXX-TODO: currently nobody ensure it.
    if ($config->yes('use_article_summary_file_expire')) {
	my $id = $#$too_old_files || -1;
	if ($id >= 0) {
	    my $first_article_seq = 1;
	    my $last_article_seq  = basename($too_old_files->[ $id ]);

	    use FML::Article::Summary;
	    my $summary = new FML::Article::Summary $curproc;
	    if ($first_article_seq <= $last_article_seq) {
		$summary->expire($first_article_seq, $last_article_seq);
	    }
	    else {
		my $msg = "$first_article_seq > $last_article_seq";
		$curproc->logdebug("expire: invalid condition $msg");
	    }
	}
    }
    else {
	$curproc->logdebug("article_summary_file_expire disabled");
    }
}


# Descriptions: find too old articles in $spool_dir.
#               If a file which mtime < $threshold_mtime,
#               we call it "too old file".
#    Arguments: OBJ($self) STR($spool_dir) NUM($threshold_mtime)
# Side Effects: none
# Return Value: ARRAY_REF
sub _find_too_old_articles
{
    my ($self, $spool_dir, $threshold_mtime) = @_;
    my $curproc = $self->{ _curproc };

    # ASSERT
    unless ($threshold_mtime > 0) {
	$curproc->logerror("article expire: $threshold_mtime <= 0");
	return;
    }
    unless ($threshold_mtime < time) {
	$curproc->logerror("article expire: $threshold_mtime >= now");
	return;
    }

    # set up global variables to pass to __check_mtime().
    $global_threshold_mtime = $threshold_mtime;

    use File::Find;
    find(\&__check_mtime, $spool_dir);

    # XXX @global_too_old_article_list set up by __check_mtime().
    return \@global_too_old_article_list;
}


# Descriptions: store too old articles in @global_too_old_article_list.
#    Arguments: none
# Side Effects: store too old file list into @global_too_old_article_list.
# Return Value: none
sub __check_mtime
{
    my $limit = $global_threshold_mtime;

    use File::stat;
    my $file = $File::Find::name;
    my $st   = stat($file);
    if (defined $st) {
	if ($st->mtime < $limit) {
	    push(@global_too_old_article_list, $file);
	}
    }
}


=head1 UTILITY

=head2 filepath($id)

return article file path corresponding with the specified $id.

=head2 subdirpath($id)

return subdir path corresponding with the specified $id.

=cut


# Descriptions: return article file path corresponding with the specified $id.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: STR(file path)
sub filepath
{
    my ($self, $id) = @_;
    my ($file_path, $dir_path) = $self->_filepath($id);
    return $file_path;
}


# Descriptions: return subdir path corresponding with the specified $id.
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


#
# DEBUG
#
if ($0 eq __FILE__) {
    use FML::Process::Debug;
    my $curproc = new FML::Process::Debug;
    my $article = new FML::Article $curproc;

    my $spool_dir = "/var/spool/ml/elena/spool";
    my $threshold = time - 14 * 24 * 3600;
    my $list = $article->_find_too_old_articles($spool_dir, $threshold);
    for my $file (@$list) {
	print STDERR "TOO OLD: $file\n";
    }
}


=head1 SEE ALSO

L<FML::Header>,
L<Mail::Message>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Article first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
