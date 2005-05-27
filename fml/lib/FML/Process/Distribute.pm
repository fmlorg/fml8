#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Distribute.pm,v 1.158 2004/12/05 16:19:09 fukachan Exp $
#

package FML::Process::Distribute;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Distribute -- article distributer library.

=head1 SYNOPSIS

   use FML::Process::Distribute;
   ...

See L<FML::Process::Flow> for details of the fml flow.

=head1 DESCRIPTION

C<FML::Process::Flow::ProcessStart($obj, $args)> drives the fml flow
where C<$obj> is the object C<FML::Process::$module::new()> returns.

=head1 METHOD

=head2 new($args)

create C<FML::Process::Distribute> object.
C<$curproc> is the object C<FML::Process::Kernel> returns but
we bless it as C<FML::Process::Distribute> object again.

=cut


# Descriptions: standard constructor.
#               sub class of FML::Process::Kernel
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(FML::Process::Distribute)
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 prepare($args)

forward the request to the base class.
adjust ml_* and load configuration files.

=cut


# Descriptions: prepare miscellaneous work before the main routine starts.
#               adjust ml_* and load configuration files.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'distribute_prepare_start_hook' )   || '';
    $eval   .= $config->get_hook( 'article_post_prepare_start_hook' ) || '';
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();
    $curproc->log_message_init();

    if ($config->yes('use_article_post_function')) {
	$curproc->parse_incoming_message();
    }
    else {
	$curproc->logerror("use of distribute_program prohibited");
	exit(0);
    }

    $eval  = $config->get_hook( 'distribute_prepare_end_hook' );
    $eval .= $config->get_hook( 'article_post_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

check the mail sender and the mail loop possibility.

=cut


# Descriptions: verify the mail sender and others
#               1. verify user credential
#               2. primitive loop check
#               3. filter
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'distribute_verify_request_start_hook' );
    $eval   .= $config->get_hook( 'article_post_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->verify_sender_credential();

    unless ($curproc->is_refused()) {
	$curproc->simple_loop_check();
    }

    unless ($curproc->is_refused()) {
	$curproc->_check_filter();
    }

    if ($curproc->filter_state_get_tempfail_request()) {
	$curproc->exit_as_tempfail(); # XXX LONG JUMP!
        # NOT REACH HERE
    }

    $eval  = $config->get_hook( 'distribute_verify_request_end_hook' );
    $eval .= $config->get_hook( 'article_post_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: apply several filters.
#    Arguments: OBJ($curproc)
# Side Effects: set flag to ignore this process if it should be filtered.
# Return Value: none
sub _check_filter
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    if ($config->yes('use_article_filter')) {
	my $eval = $config->get_hook( 'article_filter_start_hook' );
	if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

	eval q{
	    use FML::Filter;
	    my $filter = new FML::Filter $curproc;
	    my $r = $filter->article_filter($curproc);

	    # filter traps this message.
	    if ($r = $filter->error()) {
		if ($config->yes('use_article_filter_reject_notice')) {
		    my $msg_args = {
			_arg_reason => $r,
		    };

		    $curproc->log("article_filter: inform rejection");
		    $filter->article_filter_reject_notice($curproc, $msg_args);
		}
		else {
		    $curproc->logdebug("filter: not inform rejection");
		}

		# we should stop this process ASAP.
		$curproc->stop_this_process();
		$curproc->logerror("rejected by filter due to $r");
	    }
	};
	$curproc->log($@) if $@;

	$eval = $config->get_hook( 'article_filter_end_hook' );
	if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
    }
    else {
	$curproc->logdebug("article_filter disabled");
    }
}


=head2 run($args)

Firstly it locks (giant lock) the current process.

If the mail sender is one of our mailing list member,
we can distribute the mail as an article.
If not, we inform "you are not a member" which is sent by
C<inform_reply_messages()> in C<FML::Process::Kernel>.

Lastly we unlock the current process.

=cut


# Descriptions: the main routine, kick off _deliver_article_prep().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: distribution of articles.
#               See _deliver_article_prep() for more details.
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };
    my $sender     = $curproc->{'credential'}->{'sender'};
    my $_data_type =
	$config->{ article_post_restrictions_reject_notice_data_type };
    my $data_type  = $_data_type || 'string';
    my $size       = 2048;
    my $msg_args   = {
	recipient    => $sender,
	_arg_address => $sender,
	_arg_size    => $size,
    };

    my $eval = $config->get_hook( 'distribute_run_start_hook' );
    $eval   .= $config->get_hook( 'article_post_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # $curproc->lock();
    unless ($curproc->is_refused()) {
	if ($curproc->permit_post()) {
	    $curproc->_deliver_article_prep($args);
	}
	else {
	    $curproc->logerror("deny article submission");
	    $curproc->stop_this_process();

	    # send back deny request with the original message.
	    $curproc->restriction_state_reply_reason('article_post',
						     $msg_args);

	    # with original message.
	    my $msg = $curproc->incoming_message();
	    if ($data_type eq 'string') {
		my $s = $msg->whole_message_as_str( {
		    indent => '   ',
		    size   => $size,
		} );
		my $r = "The first $size bytes of this message follows:";
		$curproc->reply_message_nl("error.reject_notice_preamble",
					   $r,
					   $msg_args);
		$curproc->reply_message(sprintf("\n\n%s", $s), $msg_args);
	    }
	    else {
		$curproc->reply_message( $msg, $msg_args );
	    }

	    # inform maintainer too.
	    $msg_args->{ recipient } = $maintainer;
	    $curproc->reply_message_nl("error.post_from_not_member",
				       "post from not a member",
				       $msg_args);
	    if ($data_type eq 'string') {
		my $s = $msg->whole_message_as_str( { indent => '   ' } );
		$curproc->reply_message(sprintf("\n\n%s", $s), $msg_args );
	    }
	    else {
		$curproc->reply_message( $msg, $msg_args );
	    }
	}
    }
    else {
	$curproc->logwarn("ignore this request.");
    }

    # $curproc->unlock();

    $eval  = $config->get_hook( 'distribute_run_end_hook' );
    $eval .= $config->get_hook( 'article_post_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 help()

=cut


# Descriptions: show help.
#    Arguments: none
# Side Effects: none
# Return Value: none
sub help
{
print <<"_EOF_";

Usage: $0 \$ml_home_prefix/\$ml_name [options]

   For example, distribute of elena\@fml.org ML
   $0 elena\@fml.org

_EOF_
}


=head2 finish($args)

Finalize the current process.
If needed, we send back error messages to the mail sender.

=cut


# Descriptions: clean up in the end of the curreen process.
#               return error messages et. al.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: queue flush
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'distribute_finish_start_hook' );
    $eval   .= $config->get_hook( 'article_post_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # XXX [queue-based-distrbute] HACK
    # deferred delivery starts !
    unless ($curproc->is_refused()) {
	$curproc->_deliver_article();
    }

    $curproc->inform_reply_messages();
    unless ($curproc->smtp_server_state_get_error()) {
	$curproc->queue_flush();
    }
    else {
	$curproc->logwarn("not queue flush due to MTA fatal error.");
    }

    $eval  = $config->get_hook( 'distribute_finish_end_hook' );
    $eval .= $config->get_hook( 'article_post_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

}


# Descriptions: the top level routine to prepare article to deliver and
#               spool and queue-in the article for later delivery process.
#                  $article->header_rewrite();
#                  $article->increment_id();
#                  $article->spool();
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: header rewrite
#               the article sequence number is incremanted
#               article spooling.
# Return Value: none
sub _deliver_article_prep
{
    my ($curproc, $args) = @_;
    my $config           = $curproc->config();

    # XXX_LOCK_CHANNEL: article_spool_modify
    # exclusive lock for both sequence updating and spool writing
    my $lock_channel = "article_spool_modify";

    $curproc->lock($lock_channel);

    # XXX $article != $curproc->{ article } (which is just a key)
    # XXX $curproc->{ article } is prepared as a side effect for the future.
    my $article = $curproc->_build_article_object();

    # get sequence number
    my $id = $article->increment_id;
    if ($id > 0) {
	$curproc->set_article_id($id);
    }
    else {
	$curproc->logerror("returned article id=$id");
	$curproc->logerror("article sequence number not updated");
	$curproc->unlock($lock_channel);
	$curproc->exit_as_tempfail(); # XXX LONG JUMP!
	# NOT REACH HERE
    }

    # XXX debug, remove here in the future
    if ($debug) {
	my $ha_msg = $curproc->{ article }->{ body }->data_type_list;
	for my $msg (@$ha_msg) { $curproc->logdebug($msg);}
    }

    # thread system checks the message before header rewritings.
    if ($config->yes('use_thread_track')) {
	# $curproc->_old_thread_check();
	$curproc->_new_thread_check();
    }

    # header operations
    # XXX we need $curproc->{ article }, which is prepared above.
    $curproc->_header_rewrite({ id => $id });

    # spool in the article before delivery
    $article->spool_in($id);

    # update summary
    use FML::Article::Summary;
    my $summary = new FML::Article::Summary $curproc;
    $summary->append($article, $id);

    # update header info to sync w/ article header.
    if ($config->yes('use_thread_track')) {
	$curproc->_new_thread_check_post();
    }

    $curproc->unlock($lock_channel);

    # XXX [queue-based-distrbute] HACK
    # delivery starts !
    # $curproc->_deliver_article();

    if ($config->yes('use_html_archive')) {
	$curproc->log("htmlify article $id");
	$curproc->_htmlify();
	$curproc->logdebug("htmlify article $id end");
    }
}


# Descriptions: build and return FML::Article object.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: OBJ(FML::Article)
sub _build_article_object
{
    my ($curproc) = @_;

    # create aritcle to distribute
    use FML::Article;

    # Side Effects: $article->{ curproc } = $curproc;
    return new FML::Article $curproc;
}


# Descriptions: header rewrite followed by
#               $config->{ article_header_rewrite_rules }
#               each method exists in FML::Header module.
#    Arguments: OBJ($curproc) HASH_REF($hrw_args)
# Side Effects: $curproc->{ article }->{ header } is rewritten
# Return Value: none
sub _header_rewrite
{
    my ($curproc, $hrw_args) = @_;
    my $config = $curproc->config();
    my $header = $curproc->article_message_header();
    my $rules  = $config->get_as_array_ref('article_header_rewrite_rules');
    my $id     = $hrw_args->{ id };

    my $eval = $config->get_hook( 'article_header_rewrite_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

  RULE:
    for my $rule (@$rules) {
	$curproc->logdebug("_header_rewrite( $rule )");

	if ($header->can($rule)) {    # See FML::Header and FML::Header::*
	    $header->$rule($config, { # for methods themself
		mode => 'distribute',
		id   => $id,
	    });
	}
	else {
	    $curproc->logerror("header->$rule is undefined");
	}
    }

    # spam/virus checker
    my $is_spam  = $curproc->filter_state_spam_checker_get_error()  || '';
    my $is_virus = $curproc->filter_state_virus_checker_get_error() || '';
    if ($is_spam || $is_virus) {
	my $r = '';
	if ($is_spam) {
	    $r .= $r ? " " : '';
	    $r .= "SPAM=YES ($is_spam)";
	}
	if ($is_virus) {
	    $r .= $r ? ", " : '';
	    $r .= "VIRUS=YES ($is_virus)";
	}
	$header->add("X-ML-Content-Filter", $r) if $r;
    }
    else {
	$header->add("X-ML-Content-Filter", "SPAM=NO VIRUS=NO") if 0;
    }

    $eval = $config->get_hook( 'article_header_rewrite_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


# Descriptions: deliver the article.
#    Arguments: OBJ($curproc)
# Side Effects: mail delivery, logging
# Return Value: none
sub _deliver_article
{
    my ($curproc) = @_;
    my $cred    = $curproc->{ credential };
    my $config  = $curproc->config();                 # FML::Config   object
    my $message = $curproc->article_message();        # Mail::Message object
    my $header  = $curproc->article_message_header(); # FML::Header   object
    my $body    = $curproc->article_message_body();   # Mail::Message object

    #
    # SANITY
    #

    unless ( $config->yes( 'use_article_delivery' ) ) {
	$curproc->log("not delivery (\$use_article_delivery = no)");
	return;
    }

    # SMTP-FROM is a must!
    unless ( $config->{'maintainer'} ) {
	$curproc->logerror("not delivery for undefined \$maintainer");
	return;
    }

    # XXX_LOCK_CHANNEL: recipient_map_modify
    my $lock_channel = "recipient_map_modify";

    #
    # MAIN ### XXX [queue-based-distrbute] HACK ###
    #
    # 1. queue in (which is a little different from ordinary queue-in)
    use Mail::Delivery::Queue;
    my $queue_dir = $config->{ mail_queue_dir };
    my $queue     = new Mail::Delivery::Queue { directory => $queue_dir };
    my $qid       = $queue->id();
    my $fatal     = 0;
    if (defined $queue) {
	$curproc->lock($lock_channel);

	$curproc->logdebug("article: qid=$qid");

	$queue->set('sender', $config->{ smtp_sender });

	my $maps = $config->get_as_array_ref('recipient_maps');
	$queue->set('recipient_maps', $maps);

	$queue->in($message);
	my $n = $queue->write_count();
	$curproc->logdebug("queue: size=$n written");
	if ($queue->error()) {
	    my $error = $queue->error();
	    $curproc->logerror("queue: $error");
	    $fatal = 1;
	}

	$queue->lock( { lock_before_runnable => "yes" } );
	unless ($queue->setrunnable()) {
	    $curproc->logerror("queue: cannot setrunnable");
	    $curproc->logwarn("try to deliver on the fly");
	    $fatal = 1;
	}

	$curproc->unlock($lock_channel);
    }
    else {
	# XXX-TODO: o.k. ? 
	$curproc->logerror("queue: cannot initialize queue system");
	$fatal = 1;
    }

    # 2. distribute article
    my $fp  = sub { $curproc->logdebug(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $handle = undef;

    # overload $sfp log function pointer.
    my $wh = $curproc->open_outgoing_message_channel();
    if (defined $wh) {
	$sfp    = sub { print $wh @_;};
	$handle = undef; # $wh;
    }

    # delay loading of module
    my $service = {};
    eval q{
	use Mail::Delivery;
	$service = new Mail::Delivery {
	    log_function      => $fp,
	    smtp_log_function => $sfp,
	    smtp_log_handle   => $handle,
	};
    };
    croak($@) if $@;

    if ($service->error) {
	$curproc->logerror($service->error);
	$curproc->logerror("article: retry qid=$qid later");
	$curproc->smtp_server_state_set_error();
	return;
    }

    # replace recipient_maps if $quque creation succeed.
    my $recipient_maps = $config->{recipient_maps};
    if (defined $queue) {
	unless ($fatal) {
	    $recipient_maps = $queue->recipients_file_path($qid);
	}
    }
    else {
	# XXX-TODO ?
    }

    $curproc->lock($lock_channel) unless defined $queue;
    $service->deliver(
		      {
			  'smtp_servers'    => $config->{'smtp_servers'},

			  'smtp_sender'     => $config->{'smtp_sender'},
			  'recipient_maps'  => $recipient_maps,
			  'recipient_limit' => $config->{smtp_recipient_limit},

			  'message'         => $message,

			  map_params        => $config,

			  # fallback
			  use_queue_dir     => 1,
			  queue_dir         => $queue_dir,
		      });
    $curproc->unlock($lock_channel) unless defined $queue;

    if ($service->error) {
	$curproc->logerror($service->error);
	$curproc->smtp_server_state_set_error();
    }

    # XXX [queue-based-distrbute] HACK ###
    # here, Mail::Delivery already processes whole or a part of delivery.
    # So, we can remove queue since Mail::Delivery supports fallback
    # and creats a new queue for recipients not sent to.
    if (defined $queue) {
	$queue->remove();
	$queue->unlock();
	$curproc->logdebug("article: qid=$qid removed");
    }
}


# Descriptions: the top level interface to drive thread tracking system.
#    Arguments: OBJ($curproc)
# Side Effects: update thread information
# Return Value: none
sub _new_thread_check
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    my $msg = $curproc->article_message();

    # XXX we need to specify article_id here since
    # XXX analyzer routine has no clue for the current primary key.
    my $article_id    = $pcb->get('article', 'id');
    my $tdb_args      = $curproc->thread_db_args();
    $tdb_args->{ id } = $article_id;

    use FML::Article::Thread;
    my $article_thread = new FML::Article::Thread $curproc, $tdb_args;
    $article_thread->add_article($article_id, $msg);
}


# Descriptions: the top level interface to drive thread tracking system.
#    Arguments: OBJ($curproc)
# Side Effects: update thread information
# Return Value: none
sub _new_thread_check_post
{
    my ($curproc) = @_;
    my $pcb = $curproc->pcb();
    my $hdr = $curproc->article_message_header();

    use Mail::Message::Thread;

    # XXX we need to specify article_id here since
    # XXX analyzer routine has no clue for the current primary key.
    my $article_id    = $pcb->get('article', 'id');
    my $tdb_args      = $curproc->thread_db_args();
    $tdb_args->{ id } = $article_id;

    # overwrite header info base on the article.
    my $thread = new Mail::Message::Thread $tdb_args;
    my $db     = $thread->db();

    for my $key (qw(subject)) {
	$db->set("article_$key", $article_id, $hdr->get($key));
    }
}


# Descriptions: the top level entry to create HTML article.
#    Arguments: OBJ($curproc)
# Side Effects: update html database
# Return Value: none
sub _htmlify
{
    my ($curproc)    = @_;
    my $config       = $curproc->config();
    my $pcb          = $curproc->pcb();
    my $myname       = $curproc->myname();
    my $ml_name      = $config->{ ml_name };
    my $spool_dir    = $config->{ spool_dir };
    my $html_dir     = $config->{ html_archive_dir };
    my $udb_dir      = $config->{ udb_base_dir };
    my $article      = $curproc->_build_article_object();
    my $article_id   = $pcb->get('article', 'id');
    my $article_file = $article->filepath($article_id);
    my $index_order  = $config->{ html_archive_index_order_type };
    my $_tdb_args    = $curproc->thread_db_args();

    $curproc->set_umask_as_public();

    eval q{
	use Mail::Message::ToHTML;
    };
    unless ($@) {
	unless (-d $html_dir) {
	    $curproc->mkdir($html_dir, "mode=public");
	    $curproc->logerror("fail to mkdir $html_dir") unless -d $html_dir;
	}

	eval q{
	    my $obj = new Mail::Message::ToHTML $_tdb_args;
	    $obj->htmlify_file($article_file, $_tdb_args);
	};
	$curproc->logerror($@) if $@;
    }
    else {
	$curproc->logerror($@) if $@;
    }

    $curproc->reset_umask();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Distribute first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
