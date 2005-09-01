#-*- perl -*-
#
# Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Thread.pm,v 1.15 2005/08/17 12:08:39 fukachan Exp $
#

package FML::Article::Thread;

use vars qw($debug @ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $print_mode
	    %print_switch);
use strict;
use Carp;

# STATES
my $state_open        = "open";
my $state_analyzed    = "analyzed";
my $state_followed    = "followed";
my $state_closed      = "closed";
my $state_auto_closed = "closed(auto)";

# DISPATCH TABLE
$print_mode   = 'text';
%print_switch = (
		 text => {
		     summary => \&_psw_message_queue_text_summary_print,
		     list    => \&_psw_message_queue_text_list_print,
		 },

		 html => {
		     summary => \&_psw_message_queue_html_summary_print,
		     list    => \&_psw_message_queue_html_list_print,
		 },
		 );


=head1 NAME

FML::Article::Thread -- primitive thread tracking system

=head1 SYNOPSIS

See FML::Process::Distribute, FML::Command::Admin::thread classes for
more details.

=head1 DESCRIPTION

This class drives primitive thread tracking system at the top level.

We need to clarify the status of each article and each thread.

One thread begins at an article id and contians a group of articles as
members in it. Each thread has a status such that it is open, analyzed
or closed now.

Each article has each meaning. A new article opens and starts a new
thread. Content of an article closes a thread or threads. Also, he/she
can close a thread by manual via command mail or CUI/GUI interface.

A group of status of articles affects the status of threads.
So, we need to trace status of articles and threads separetely.

If explicitly not closed, the status of a thread is either of
"closed(auto)" or "analyzed".

=head1 METHOD

=head2 new($curproc)

constructor.

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
	my $max_id = $curproc->article_get_max_id();
	$tdb_args  = $curproc->article_thread_init();
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


=head1 HANDLE ARTICLE

=head2 add_article($id, $msg)

check the content of specified article $id to update UDB where $msg is
a Mail::Message object.

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

    # 1) get subject. mime-decode it if needed.
    my $subject = $header->get('subject');
    if ($subject =~ /=\?/o) {
	my $string = new Mail::Message::String $subject;
	$string->mime_decode();
	$string->charcode_convert_to_internal_code();
	$subject = $string->as_str();
    }

    # 2) it looks the subject has a reply tag ?
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

    # check the current thread status 
    # XXX for thread, not each member !
    my $status = $thread->get_thread_status($head_id);
    if ($status eq $state_closed || $status eq $state_auto_closed) {
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
		    if (defined $msg) {
			if ($msg->has_closing_phrase()) {
			    $status = $state_auto_closed;
			}
		    }
		}
	    }

	    if ($status eq $state_closed || $status eq $state_auto_closed) {
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

    $self->_change_thread_status("open", $thread_args, $state_open);
}


# Descriptions: close thread.
#    Arguments: OBJ($self) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub close_thread_status
{
    my ($self, $thread_args) = @_;

    $self->_change_thread_status("close", $thread_args, $state_closed);
}


# Descriptions: open/close thread with the specified range.
#    Arguments: OBJ($self) STR($action) HASH_REF($thread_args) STR($state)
# Side Effects: update UDB.
# Return Value: none
sub _change_thread_status
{
    my ($self, $action, $thread_args, $state) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };

    use Mail::Message::MH;
    my $mh      = new Mail::Message::MH;
    my $range   = $thread_args->{ range } || 'last:10';
    my $head_id = $thread_args->{ last_id };
    my $id_list = $mh->expand($range, 1, $head_id);

    for my $id (@$id_list) {
	$curproc->log("$action thread $id");
	$thread->set_thread_status($id, $state);
    }
}


=head1 SUMMARY

=head2 get_overview($id, $thread_args)

return string holding article short summaries of a thread for this
article $id.

=cut


# Descriptions: return a bulk of brief summary. 
#    Arguments: OBJ($self) NUM($id) HASH_REF($thread_args)
# Side Effects: none
# Return Value: none
sub get_overview
{
    my ($self, $id, $thread_args) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $head_id = $thread->db->find_head_key($id);
    my $fp      = "one_line_summary";
    my $buf     = '';

    $thread_args->{ range }   = sprintf("%s-%s", $head_id, $id);
    $thread_args->{ last_id } = $id;
    my $queue = $self->_generate_message_queue($fp, $thread_args);
    for my $q (@$queue) {
	my $s = $q->{ summary } || '';
	$s =~ s/^\s*//;
	$s =~ s/\s*$//;
	if ($s) {
	    $buf .= sprintf("   %s\n", $s);
	}
    }

    return $buf;
}


=head1 PRINT STATUS OR SUMMARY

=head2 print_one_line_summary($thread_args)

pritn one line summary of message body.

=head2 print_summary($thread_args)

pritn both header and body summary. 

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
    my $curproc = $self->{ _curproc };

    my $queue = $self->_generate_message_queue($fp, $thread_args);
    my $pfp   = $print_switch{ $print_mode }->{ summary };
    $self->$pfp($curproc, $queue);
}


# Descriptions: prepare the corresponding message queue with this thread.
#    Arguments: OBJ($self) STR($fp) HASH_REF($thread_args)
# Side Effects: none
# Return Value: ARRAY_REF
sub _generate_message_queue
{
    my ($self, $fp, $thread_args) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };
    my $queue   = [];

    # here we go.
    my $summary = $thread->get_thread_data($thread_args);

  THREAD:
    for my $head_id (sort {$a <=> $b} keys %$summary) {
	# firstly check thread status.
	my $status = $thread->get_thread_status($head_id) || "open";
	next THREAD if $status eq $state_closed;
	next THREAD if $status eq $state_auto_closed;

	my $list = $summary->{ $head_id } || [];
	for my $id (@$list) {
	    my $buf = '';

	    if ($fp eq 'one_line_summary') {
		$buf = $thread->get_article_summary($id) || '';
	    }

	    unless ($buf) {
		$buf = $self->_generate_summary($fp, $thread_args, $id) || '';
	    }

	    # prepare printing data queue.
	    my $q = {
		cur_id  => $id,
		head_id => $head_id,
		id_list => $list,
		status  => $status,
		summary => $buf,
	    };
	    push(@$queue, $q);
	} # for my $id (@$list) { ...; }
    }

    return $queue;
}


# Descriptions: generate summary from the original article file.
#    Arguments: OBJ($self) STR($fp) HASH_REF($thread_args) NUM($id)
# Side Effects: none
# Return Value: STR
sub _generate_summary
{
    my ($self, $fp, $thread_args, $id) = @_;
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };
    my $buf     = '';

    my $article_path = $article->filepath($id);

    use FileHandle;
    my $fh = new FileHandle $article_path;
    if (defined $fh) {
	use Mail::Message;
	my $msg = Mail::Message->parse(  { fd => $fh } );
	$buf = $msg->$fp();

	# cache on.
	if ($buf && $fp eq 'one_line_summary') { 
	    $thread->set_article_summary($id, $buf);
	}
    }
    else {
	$curproc->logerror("no such file: $article_path");
    }

    return $buf;
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
    my $curproc = $self->{ _curproc };
    my $thread  = $self->{ _thread_object };
    my $article = $self->{ _article_object };
    my $summary = $thread->get_thread_data($thread_args);
    my $queue   = [];

  THREAD:
    for my $head_id (sort {$a <=> $b} keys %$summary) {
	my $status = $thread->get_thread_status($head_id) || "open";
	next THREAD if $status eq $state_closed;
	next THREAD if $status eq $state_auto_closed;

	my $list = $summary->{ $head_id } || [];
	my $q = {
	    head_id => $head_id,
	    id_list => $list,
	    status  => $status,
	};
	push(@$queue, $q);
    }

    my $pfp = $print_switch{ $print_mode }->{ list };
    $self->$pfp($curproc, $queue);
}


=head1 DEFAULT PRINT ENGINES

=cut


# Descriptions: set mode of output.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: update package scope $print_mode variable.
# Return Value: none
sub set_print_style
{
    my ($self, $mode) = @_;

    if (defined $mode) {
	if ($mode eq 'text' || $mode eq 'html') {
	    $print_mode = $mode;
	}
    }
}


# Descriptions: set mode of output.
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: update package scope %print_switch dispatcher table.
# Return Value: none
sub set_print_function
{
    my ($self, $key, $value) = @_;

    if (ref($value) eq 'CODE') {
	$print_switch{ $print_mode }->{ $key } = $value;
    }
    else {
	croak("set_print_function: invalid data");
    }
}


# Descriptions: default print engine for summary.
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($queue)
# Side Effects: none
# Return Value: none
sub _psw_message_queue_text_summary_print
{
    my ($self, $curproc, $queue) = @_;

    for my $q (@$queue) {
	my $cur_id  = $q->{ cur_id }  || '';
	my $head_id = $q->{ head_id } || '';
	my $id_list = $q->{ id_list } || [];
	my $status  = $q->{ status }  || 'unknown';
	my $summary = $q->{ summary } || '';
	my $wh      = $q->{ output_channel } || \*STDOUT;
	my $prompt  = ">>>";

	if ($cur_id && $head_id) {
	    if ($head_id == $cur_id) {
		print $wh "$prompt article thread";
		print $wh " (@$id_list)";
		print $wh " status=$status\n";
	    }

	    $summary =~ s/^\s*/   /;
	    $summary =~ s/\n\s*/\n   /g;
	    print $wh $summary;

	    print $wh "\n";
	}
	else {
	    carp("_psw_message_queue_text_summary_print: invalid data");
	}
    }
}


# Descriptions: default print engine for list.
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($queue)
# Side Effects: none
# Return Value: none
sub _psw_message_queue_text_list_print
{
    my ($self, $curproc, $queue) = @_;

    for my $q (@$queue) {
	my $head_id = $q->{ head_id } || '';
	my $id_list = $q->{ id_list } || [];
	my $status  = $q->{ status }  || 'unknown';
	my $wh      = $q->{ output_channel } || \*STDOUT;
	my $format  = "%-12s %s\n";

	if (@$id_list) {
	    printf $wh $format, $status, join(" ", @$id_list);
	}
	else {
	    printf $wh $format, $status, $head_id;
	}
    }
}


# Descriptions: default print engine for summary.
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($queue)
# Side Effects: none
# Return Value: none
sub _psw_message_queue_html_summary_print
{
    my ($self, $curproc, $queue) = @_;
    my $q  = $queue->[ 0 ] || {};
    my $wh = $q->{ output_channel } || \*STDOUT;

    print $wh "<table border=4>\n";

    for my $q (@$queue) {
	my $cur_id  = $q->{ cur_id }  || '';
	my $head_id = $q->{ head_id } || '';
	my $id_list = $q->{ id_list } || [];
	my $status  = $q->{ status }  || 'unknown';
	my $summary = $q->{ summary } || '';
	my $wh      = $q->{ output_channel } || \*STDOUT;
	my $prompt  = "";

	print $wh "<tr>\n";

	if ($cur_id && $head_id) {
	    if ($head_id == $cur_id) {
		print $wh "<td> @$id_list";
		print $wh "<td> $status\n";
	    }
	    else {
		print $wh "<td>\n";
		print $wh "<td>\n";
	    }

	    print $wh "<td>\n";
	    $summary =~ s/^\s*/   /;
	    $summary =~ s/\n\s*/\n   /g;
	    print $wh $summary;

	    print $wh "<BR>\n";
	}
	else {
	    carp("_psw_message_queue_html_summary_print: invalid data");
	}
    }

    print $wh "</table>\n";
}


# Descriptions: default print engine for list.
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($queue)
# Side Effects: none
# Return Value: none
sub _psw_message_queue_html_list_print
{
    my ($self, $curproc, $queue) = @_;
    my $q  = $queue->[ 0 ] || {};
    my $wh = $q->{ output_channel } || \*STDOUT;

    print $wh "<table border=4>\n";

    for my $q (@$queue) {
	my $head_id = $q->{ head_id } || '';
	my $id_list = $q->{ id_list } || [];
	my $status  = $q->{ status }  || 'unknown';
	my $wh      = $q->{ output_channel } || \*STDOUT;

	print $wh "<tr>\n";
	if (@$id_list) {
	    print $wh "<td>\n";
	    print $wh  $status;
	    print $wh "<td>\n";
	    print $wh join(" ", @$id_list);
	}
	else {
	    print $wh "<td>\n";
	    print $wh  $status;
	    print $wh "<td>\n";
	    printf $wh $head_id;
	}
    }

    print $wh "</table>\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
