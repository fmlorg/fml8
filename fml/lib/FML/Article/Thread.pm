#-*- perl -*-
#
# Copyright (C) 2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Thread.pm,v 1.4 2003/08/23 14:37:59 fukachan Exp $
#

package FML::Article::Thread;

use vars qw($debug @ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


# STATES
my $state_open        = "open";
my $state_analyzed    = "analyzed";
my $state_followed    = "followed";
my $state_closed      = "closed";
my $state_auto_closed = "closed(auto)";


=head1 NAME

FML::Article::Thread -- primitive thread tracking system

=head1 SYNOPSIS

See FML::Process::Distribute, FML::Command::Admin::thread classes for
more details.

=head1 DESCRIPTION

This class drives primitive thread tracking system at the top level.

We need to clarify the status of each article and each thread.

One thread begins at an article id and contians a group of articles as
members in it. Each thread has a status such that it is open now,
analyzed or closed now.

Each article has each meaning. A new article opens and starts a new
thraed.  Whereas, content of an article closes a thread or threads.
Also, he/she closes a thread by manual via command mail or CUI/GUI
interface.

A group of status of articles affects the status of threads.
So, we need to trace status of articles and threads separetely.

If explicitly not closed, the status of a thread is either of
"closed(auto)" or "analyzed".

=head1 METHOD

=head2 new($curproc)

create a C<FML::Process::Kernel> object and return it.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($thread_db_args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc, $thread_db_args) = @_;
    my $type = ref($self) || $self;
    my $me   = { _curproc => $curproc };

    # initialize thread object.
    my $tdb_args = undef;
    if (defined $thread_db_args) {
	$tdb_args = $thread_db_args;
    }
    else {
	my $max_id = $curproc->article_max_id();
	$tdb_args  = $curproc->thread_db_args();
	$tdb_args->{ id } = $max_id;
    }

    use Mail::Message::Thread;
    my $thread  = new Mail::Message::Thread $tdb_args;
    $me->{ _thread_object } = $thread;

    # initialize $article object.
    use FML::Article;
    my $article = new FML::Article $curproc;
    $me->{ _article_object } = $article;

    return bless $me, $type;
}


=head1 SHOW STATUS

=head2 print_one_line_summary($thread_args)

=head2 print_summary($thread_args)

=cut


# Descriptions: print one line summary.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub print_one_line_summary
{
    my ($self, $thread_args) = @_;
    my $id = $thread_args->{ last_id } || 0;

    if ($id) {
	$self->_print_summary("one_line_summary", $thread_args);
    }
}


# Descriptions: print summary.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub print_summary
{
    my ($self, $thread_args) = @_;
    my $id = $thread_args->{ last_id } || 0;

    if ($id) {
	$self->_print_summary("summary", $thread_args);
    }
}


# Descriptions: actual engine to print summary.
#               $thread_args = {
#                       last_id => last (max) id of our target range,
#                       range   => MH style range,
#               }
#    Arguments: OBJ($self) STR($fp) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub _print_summary
{
    my ($self, $fp, $thread_args) = @_;
    my $curproc  = $self->{ _curproc };
    my $thread   = $self->{ _thread_object };
    my $article  = $self->{ _article_object };
    my $prompt   = ">>>";

    # here we go.
    my $summary = $thread->get_thread_data($thread_args);
    for my $head_id (sort {$a <=> $b} keys %$summary) {
	my $list = $summary->{ $head_id } || [];

	print "$prompt article $head_id (@$list)\n";

	for my $id (@$list) {
	    my $article_path = $article->filepath($id);

	    use FileHandle;
	    my $fh = new FileHandle $article_path;
	    if (defined $fh) {
		use Mail::Message;
		my $msg = Mail::Message->parse(  { fd => $fh } );
		print $msg->$fp();
		print "\n";
	    }
	    else {
		$curproc->logerror("no such file: $article_path");
	    }
	}
    }
}


=head2 print_list($thread_args)

list up thread and the related information.

=cut


# Descriptions: list up thread and the related information.
#               $thread_args = {
#                       last_id => last (max) id of our target range,
#                       range   => MH style range,
#               }
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub print_list
{
    my ($self, $thread_args) = @_;
    my $curproc  = $self->{ _curproc };
    my $thread   = $self->{ _thread_object };
    my $article  = $self->{ _article_object };
    my $format   = "%-8s %-8d %s\n";

    my $summary = $thread->get_thread_data($thread_args);
    for my $head_id (sort {$a <=> $b} keys %$summary) {
	my $list   = $summary->{ $head_id } || [];
	my $status = "open";

	if (@$list) {
	    printf $format, $status, $head_id, join(" ", @$list);
	}
	else {
	    printf $format, $status, $head_id, '';
	}
    }
}



=head1 HANDLE STATUS

=head2 check_thread_status($head_id)

check the status of thread beginning at $head_id.
update the status in UDB if needed.

=cut


# Descriptions: check the status of this thread where the thread is
#               specified by the $head_id.
#    Arguments: OBJ($self) NUM($head_id)
# Side Effects: update UDB.
# Return Value: OBJ
sub check_thread_status
{
    my ($self, $head_id) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    # check the current thread status (XXX thread, not each member).
    my $thread_status = $thread->get_thread_status($head_id);
    if ($thread_status =~ /close/io) { # O.K. stop here.
	return;
    }

    # analyze each member in this thread and close this "thread"
    # even if found that one member looks closed.
    # $head_id => [ $head_id, $id1, $id2, ... ];
    my $id_list = $thread->get_thread_member_as_array_ref($head_id);
    if (@$id_list) {
	my $status;

      ID:
        for my $id (@$id_list) {
	    $status = $thread->get_article_status($id);
	    unless ($status) {
		if ($id) {
		    my $msg = $self->_init_message($id);
		    if ($msg->has_closing_phrase()) {
			$status = $state_auto_closed;
		    }
		}
	    }

	    if ($status =~ /close/io) {
		$thread->set_thread_status($head_id, $state_auto_closed);
		last ID;
	    }
	} # for;;
    }
}


# Descriptions: parse article (file) $id and return Mail::Message object.
#    Arguments: OBJ($self) NUM($id)
# Side Effects: none
# Return Value: OBJ
sub _init_message
{
    my ($self, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    # parse article (file) and return Mail::Message object.
    my $article_path = $article->filepath($id);
    use FileHandle;
    my $fh = new FileHandle $article_path;
    if (defined $fh) {
	use Mail::Message;
	return Mail::Message->parse(  { fd => $fh } );
    }

    return undef;
}


=head2 add_article($id, $msg)

check the status of specified article. $msg is a Mail::Message object.

This routine is expected to be called within FML::Process::Distribute.
So, $msg must be already defined.

=cut


# Descriptions: check the content of message object.
#               log and update UDB if needed.
#    Arguments: OBJ($self) NUM($id) OBJ($msg)
# Side Effects: update UDB.
# Return Value: none
sub add_article
{
    my ($self, $id, $msg) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    # analyze the current message and store the data into DB (UDB).
    # XXX this analyzer examines the basic profile of article, but
    # XXX not determine the status "open", "close" et.al. for the article.
    # XXX The determination is deferred below.
    $thread->analyze($msg);

    # analyze more details of the content and create a hint to
    # determine the thread status for later use.
    $self->check_if_article_is_reply_message($id, $msg);
    $self->check_if_article_has_closing_phrase($id, $msg);
    $self->check_if_article_should_be_ignored($id, $msg);
}


# Descriptions: check the content of message object.
#               log and update UDB if needed.
#    Arguments: OBJ($self) NUM($id) OBJ($msg)
# Side Effects: update UDB.
# Return Value: none
sub check_if_article_is_reply_message
{
    my ($self, $id, $msg) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };
    my $header  = $msg->whole_message_header();

    # 1) get subject.
    my $subject = $header->get('subject');
    if ($subject =~ /=\?/o) {
	my $string = new Mail::Message::String $subject;
	$string->mime_decode();
	$string->charcode_convert_to_internal_code();
	$subject = $string->as_str();
    }

    # 2) it looks subject has a reply tag ?
    use FML::Header::Subject;
    my $subj = new FML::Header::Subject;
    if ($subj->is_reply($subject)) {
	$thread->set_article_status($id, $state_followed);
    }
    else {
	$thread->set_article_status($id, $state_open);
    }
}


# Descriptions: check the content of message object.
#               log and update UDB if needed.
#    Arguments: OBJ($self) NUM($id) OBJ($msg)
# Side Effects: update UDB.
# Return Value: none
sub check_if_article_has_closing_phrase
{
    my ($self, $id, $msg) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    my $rules = {
	'thank you' => 1,
    };
    $msg->set_closing_phrase_rules($rules);

    # check it as "closed(auto)" if it looks like the end of thread.
    # for example, we can find some phrases, "thank you.", "this
    # problem is resolved.",...  at the last of the article.
    if ($msg->has_closing_phrase()) {
	$thread->set_article_status($id, $state_auto_closed);
    }
}


# Descriptions: check the content of message object.
#               log and update UDB if needed.
#    Arguments: OBJ($self) NUM($id) OBJ($msg)
# Side Effects: update UDB.
# Return Value: none
sub check_if_article_should_be_ignored
{
    my ($self, $id, $msg) = @_;

    # check if this article should be ignored ?
    # for example, "cvs source changes" may be ignored at some ML.
    if (0) {
	# $self->check_message_filter( file => filter_config_file ) ?
    }
}


=head1 UTILITY FUNCTIONS

=head2 open_thread_status($th_args)

open thread.

=head2 close_thread_status($th_args)

close thread.

=cut


# Descriptions: open thread.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub open_thread_status
{
    my ($self, $thread_args) = @_;

    $self->_change_thread_status($thread_args, $state_open);
}


# Descriptions: close thread.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub close_thread_status
{
    my ($self, $thread_args) = @_;

    $self->_change_thread_status($thread_args, $state_closed);
}


# Descriptions: open/close thread with the specified range.
#    Arguments: OBJ($self) HASH_REF($thread_args) STR($state)
# Side Effects: update UDB.
# Return Value: none
sub _change_thread_status
{
    my ($self, $thread_args, $state) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    use Mail::Message::MH;
    my $mh      = new Mail::Message::MH;
    my $range   = $thread_args->{ range } || 'last:10';
    my $head_id = $thread_args->{ last_id };
    my $id_list = $mh->expand($range, 1, $head_id);
    my $tail_id = $id_list->[ 0 ] || 1;

    for my $id (@$id_list) {
	$curproc->log("close thread $id");
	$thread->set_thread_status($id, $state);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
