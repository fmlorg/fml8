#-*- perl -*-
#
# Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Distribute.pm,v 1.115 2003/05/13 04:26:48 fukachan Exp $
#

package FML::Process::Distribute;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Log qw(Log LogWarn LogError);
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

=head2 C<new($args)>

create C<FML::Process::Distribute> object.
C<$curproc> is the object C<FML::Process::Kernel> returns but
we bless it as C<FML::Process::Distribute> object again.

=cut


# Descriptions: ordinary constructor.
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


=head2 C<prepare($args)>

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
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'distribute_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();

    if ($config->yes('use_distribute_program')) {
	$curproc->parse_incoming_message($args);
    }
    else {
	LogError("use of distribute_program prohibited");
	exit(0);
    }

    $eval = $config->get_hook( 'distribute_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 C<verify_request($args)>

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
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'distribute_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->verify_sender_credential();

    unless ($curproc->is_refused()) {
	$curproc->simple_loop_check();
    }

    unless ($curproc->is_refused()) {
	$curproc->_check_filter($args);
    }

    $eval = $config->get_hook( 'distribute_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


# Descriptions: filter
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: set flag to ignore this process if it should be filtered.
# Return Value: none
sub _check_filter
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    eval q{
	use FML::Filter;
	my $filter = new FML::Filter;
	my $r = $filter->article_filter($curproc, $args);

	# filter traps this message.
	if ($r = $filter->error()) {
	    if ($config->yes('use_article_filter_reject_notice')) {
		my $msg_args = {
		    _arg_reason => $r,
		};

		Log("(debug) filter: inform rejection");
		$filter->article_filter_reject_notice($curproc, $msg_args);
	    }
	    else {
		Log("filter: not inform rejection");
	    }

	    # we should stop this process ASAP.
	    $curproc->stop_this_process();
	    Log("rejected by filter due to $r");
	}
    };
    Log($@) if $@;
}


=head2 C<run($args>)

Firstly it locks (giant lock) the current process.

If the mail sender is one of our mailing list member,
we can distribute the mail as an article.
If not, we inform "you are not a member" which is sent by
C<inform_reply_messages()> in C<FML::Process::Kernel>.

Lastly we unlock the current process.

=cut


# Descriptions: the main routine, kick off _distribute()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: distribution of articles.
#               See _distribute() for more details.
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config     = $curproc->{ config };
    my $maintainer = $config->{ maintainer };
    my $sender     = $curproc->{'credential'}->{'sender'};
    my $data_type  = 
	$config->{post_restrictions_reject_notice_data_type} || 'string';
    my $size       = 2048;
    my $msg_args   = {
	_arg_address => $sender,
	recipient    => $sender,
	size         => $size, 
    };

    my $eval = $config->get_hook( 'distribute_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    # $curproc->lock();
    unless ($curproc->is_refused()) {
	if ($curproc->permit_post($args)) {
	    $curproc->_distribute($args);
	}
	else {
	    my $pcb = $curproc->{ pcb };

	    Log("deny article submission");

	    my $rule = $pcb->get("check_restrictions", "deny_reason");
	    if ($rule eq 'reject_system_accounts') {
		my $r = "deny request from a system account";
		$curproc->reply_message_nl("error.system_accounts", 
					   $r, $msg_args);
	    }
	    elsif ($rule eq 'permit_member_maps') {
		my $r = "deny request from a not member";
		$curproc->reply_message_nl("error.not_member", $r, $msg_args);
	    }
	    elsif ($rule eq 'reject') {
		my $r = "deny your request";
		$curproc->reply_message_nl("error.reject_post", $r, $msg_args);
	    }
	    else {
		my $r = "deny your request due to an unknown reason";
		$curproc->reply_message_nl("error.reject_post", $r, $msg_args);
	    }

	    # send back deny request with the original message.
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
	LogError("ignore this request.");
    }

    # $curproc->unlock();

    $eval = $config->get_hook( 'distribute_run_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }
}


=head2 help()

=cut


# Descriptions: show help
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


=head2 C<finish($args)>

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
    my $config = $curproc->{ config };

    my $eval = $config->get_hook( 'distribute_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'distribute_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; LogWarn($@) if $@; }

}


# Descriptions: the top level routine to drive the article spooling and
#               distribution.
#                  $article->header_rewrite();
#                  $article->increment_id();
#                  $article->spool();
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: header rewrite
#               the article sequence number is incremanted
#               article spooling.
# Return Value: none
sub _distribute
{
    my ($curproc, $args) = @_;
    my $config       = $curproc->config();

    # XXX_LOCK_CHANNEL: article_spool_modify
    # exclusive lock for both sequence updating and spool writing
    my $lock_channel = "article_spool_modify";

    $curproc->lock($lock_channel);

    # XXX $article != $curproc->{ article } (which is just a key)
    # XXX $curproc->{ article } is prepared as a side effect for the future.
    my $article = $curproc->_build_article_object($args);

    # get sequence number
    my $id = $article->increment_id;

    # XXX debug, remove here in the future
    if ($debug) {
	my $ha_msg = $curproc->{ article }->{ body }->data_type_list;
	for my $msg (@$ha_msg) { Log("debug: $msg");}
    }

    # thread system checks the message before header rewritings.
    $curproc->_thread_check($args) if $config->yes('use_thread_track');

    # header operations
    # XXX we need $curproc->{ article }, which is prepared above.
    $curproc->_header_rewrite({ id => $id });

    # spool in the article before delivery
    $article->spool_in($id);

    # update summary
    use FML::Article::Summary;
    my $summary = new FML::Article::Summary $curproc;
    $summary->append($article, $id);

    $curproc->unlock($lock_channel);

    # delivery starts !
    $curproc->_deliver_article($args);

    if ($config->yes('use_html_archive')) {
	Log("htmlify article $id");
	$curproc->htmlify($args);
    }
}


# Descriptions: build and return FML::Article object
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(FML::Article)
sub _build_article_object
{
    my ($curproc, $args) = @_;

    # create aritcle to distribute
    use FML::Article;

    # Side Effects: $article->{ curproc } = $curproc;
    return new FML::Article $curproc;
}


# Descriptions: header rewrite followed by
#               $config->{ article_header_rewrite_rules }
#               each method exists in FML::Header module.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: $curproc->{ article }->{ header } is rewritten
# Return Value: none
sub _header_rewrite
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $header = $curproc->article_message_header();
    my $rules  = $config->get_as_array_ref('article_header_rewrite_rules');
    my $id     = $args->{ id };

    for my $rule (@$rules) {
	Log("_header_rewrite( $rule )") if $config->yes('debug');

	if ($header->can($rule)) {    # See FML::Header and FML::Header::*
	    $header->$rule($config, { # for methods themself
		mode => 'distribute',
		id   => $id,
	    });
	}
	else {
	    LogError("header->$rule is undefined");
	}
    }
}


# Descriptions: deliver the article
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: mail delivery, logging
# Return Value: none
sub _deliver_article
{
    my ($curproc, $args) = @_;
    my $cred    = $curproc->{ credential };
    my $config  = $curproc->{ config };               # FML::Config   object
    my $message = $curproc->article_message();        # Mail::Message object
    my $header  = $curproc->article_message_header(); # FML::Header   object
    my $body    = $curproc->article_message_body();   # Mail::Message object

    unless ( $config->yes( 'use_article_delivery' ) ) {
	Log("not delivery (\$use_article_delivery = no)");
	return;
    }

    # SMTP-FROM is a must!
    unless ( $config->{'maintainer'} ) {
	Log("not delivery for undefined \$maintainer");
	return;
    }

    # distribute article
    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $handle = undef;

    # overload $sfp log function pointer.
    my $wh = $curproc->open_outgoing_message_channel();
    if (defined $wh) {
	$sfp = sub { print $wh @_;};
	$handle = undef; # $wh;
    }

    # delay loading of module
    my $service = {};
    eval q{
	use Mail::Delivery;
	$service = new Mail::Delivery {
	    log_function       => $fp,
	    smtp_log_function  => $sfp,
	    smtp_log_handle    => $handle,
	};
    };
    croak($@) if $@;

    if ($service->error) { Log($service->error); return;}

    # XXX_LOCK_CHANNEL: recipient_map_modify
    my $lock_channel = "recipient_map_modify";
    $curproc->lock($lock_channel);
    $service->deliver(
		      {
			  'smtp_servers'    => $config->{'smtp_servers'},

			  'smtp_sender'     => $config->{'smtp_sender'},
			  'recipient_maps'  => $config->{recipient_maps},
			  'recipient_limit' => $config->{smtp_recipient_limit},

			  'message'         => $message,

			  map_params        => $config,
		      });
    $curproc->unlock($lock_channel);

    if ($service->error) { Log($service->error); return;}
}


# Descriptions: the top level interface to drive thread tracking system
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: update thread information
# Return Value: none
sub _thread_check
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $pcb    = $curproc->{ pcb };
    my $myname = $curproc->myname();

    my $ml_name        = $config->{ ml_name };
    my $thread_db_dir  = $config->{ thread_db_dir };
    my $spool_dir      = $config->{ spool_dir };
    my $article_id     = $pcb->get('article', 'id');
    my $is_rewrite_hdr = $config->yes('use_thread_subject_tag') ? 1 : 0;
    my $ttargs        = {
	myname         => $myname,
	logfp          => \&Log,
	fd             => \*STDOUT,
	db_base_dir    => $thread_db_dir,
	ml_name        => $ml_name,
	spool_dir      => $spool_dir,
	article_id     => $article_id,
	rewrite_header => $is_rewrite_hdr,
    };

    my $msg = $curproc->article_message();

    eval q{
	use Mail::ThreadTrack;
	my $thread = new Mail::ThreadTrack $ttargs;
	$thread->analyze($msg);
    };

    Log($@) if $@;
}


# Descriptions: the top level entry to create HTML article
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: update html database
# Return Value: none
sub htmlify
{
    my ($curproc, $args) = @_;
    my $config       = $curproc->config();
    my $pcb          = $curproc->pcb();
    my $myname       = $curproc->myname();
    my $ml_name      = $config->{ ml_name };
    my $spool_dir    = $config->{ spool_dir };
    my $html_dir     = $config->{ html_archive_dir };
    my $udb_dir      = $config->{ udb_base_dir };
    my $article      = $curproc->_build_article_object($args);
    my $article_id   = $pcb->get('article', 'id');
    my $article_file = $article->filepath($article_id);
    my $index_order  = $config->{ html_archive_index_order_type };
    my $cur_lang     = $curproc->language_of_html_file();

    unless (-d $udb_dir) { $curproc->mkdir($udb_dir);}

    # XXX-TODO: care for non Japanese.
    my $htmlifier_args = {
	charset     => $cur_lang,

	output_dir  => $html_dir,    # ~fml/public_html/mlarchive/$domain/$ml/
	db_base_dir => $udb_dir,     # /var/spool/ml/@udb@
	db_name     => $ml_name,     # elena

	index_order => $index_order, # normal/reverse
    };

    $curproc->set_umask_as_public();

    eval q{
	use Mail::Message::ToHTML;
    };
    unless ($@) {
	unless (-d $html_dir) {
	    $curproc->mkdir($html_dir, "mode=public");
	    LogError("fail to mkdir $html_dir") unless -d $html_dir;
	}

	eval q{
	    my $obj = new Mail::Message::ToHTML $htmlifier_args;
	    $obj->htmlify_file($article_file, $htmlifier_args);
	};
	LogError($@) if $@;
    }
    else {
	LogError($@) if $@;
    }

    $curproc->reset_umask();
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Distribute first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
