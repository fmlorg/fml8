#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

package FML::Process::Distribute;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log);
use FML::Config;


=head1 NAME

FML::Process::Distribute -- fml5 article distributer library.

=head1 SYNOPSIS

   use FML::Process::Command;
   ...

See L<FML::Process::Flow> for details of flow.

=head1 DESCRIPTION

=cut


require Exporter;
@ISA = qw(FML::Process::Kernel Exporter);


sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


sub prepare
{
    my ($self, $args) = @_;
    $self->SUPER::prepare($args);
}


sub verify_request
{
    my ($curproc, $args) = @_;
    $curproc->verify_sender_credential();
}


sub run
{
    my ($curproc, $args) = @_;

    $curproc->lock();
    {
	# user credential
	my $cred = $curproc->{ credential };

	# Q: the mail sender is a ML member?
	if ($cred->is_member) {
	    # A: If so, we try to distribute this article.
	    _distribute( $curproc ); 
	}
    }
    $curproc->unlock();
}


sub finish
{
    my ($curproc, $args) = @_;

    $curproc->inform_reply_messages();
}


# $article->header_rewrite;
# $article->increment_id;
# $article->spool;
# distribute( $article );
sub _distribute
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    # XXX   $ah is "article handler" object.
    # XXX   $ah != $curproc->{ article } (which is just a key)
    # XXX   $curproc->{ article } is prepared as a side effect.
    my $ah = $curproc->_prepare_article($args);

    # get sequence number
    my $id = $ah->increment_id;

    # XXX debug, remove here in the future
    {
	my $ha_msg = $curproc->{ article }->{ body }->get_content_type_list;
	for (@$ha_msg) { Log($_);}
    }

    # ticket system checks the message before header rewritings.
    $curproc->_ticket_check($args) if $config->yes('use_ticket');

    # header operations
    # XXX we need $curproc->{ article }, which is prepared above.
    $curproc->_header_rewrite({ id => $id });

    # spool in the article before delivery
    $ah->spool_in($id);

    # delivery starts !
    $curproc->_deliver_article($args);
}


sub _prepare_article
{
    my ($curproc, $args) = @_;

    # create aritcle to distribute
    use FML::Article;

    # Side Effects: $article->{ curproc } = $curproc;
    return new FML::Article $curproc;
}


sub _header_rewrite
{
    my ($curproc, $args) = @_;

    my $config = $curproc->{ config };
    my $header = $curproc->{ article }->{ header };
    my $rules  = $curproc->{ config }->{ article_header_rewrite_rules };
    my $id     = $args->{ id };

    for my $rule (split(/\s+/, $rules)) {
	Log("_header_rewrite( $rule )") if $config->yes('debug');

	if ($header->can($rule)) {    # See FML::Header and FML::Header::*
	    $header->$rule($config, { # for methods themself
		mode => 'distribute',
		id   => $id,
	    });
	}
	else {
	    Log("Error: header->$rule is undefined");
	}
    }
}


sub _deliver_article
{
    my ($curproc, $args) = @_;

    my $config  = $curproc->{ config };             # FML::Config object;
    my $body    = $curproc->{ article }->{ body };  # MailingList::Messages object;
    my $header  = $curproc->{ article }->{ header };# FML::Header object;
	
    unless ( $config->yes( 'use_article_delivery' ) ) {
	return;
    }

    # SMTP-FROM is a must!
    unless ( $config->{'maintainer'} ) {
	Log("not delivery for undefined \$maintainer");
	return;
    }

    # distribute article
    use MailingList::Delivery;

    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};

    { # debug
	my $dir = $config->{ smtp_log_dir };
	use FML::Utils qw(mkdirhier);
	mkdirhier($dir) unless -d $dir;

	my $f = $config->{ smtp_log_file };
	unlink $f if -f $f;
	if ($f) {
	    use FileHandle;
	    my $fh = new FileHandle "> $f";
	    if (defined $fh) {
		$fh->autoflush(1);
		$sfp = sub { print $fh @_;};
	    }
	}
    }

    my $service = new MailingList::Delivery {
	log_function       => $fp,
	smtp_log_function  => $sfp,
    };
    if ($service->error) { Log($service->error); return;}

    $service->deliver(
		      {
			  'smtp_servers'    => $config->{'smtp_servers'},

			  'smtp_sender'     => $config->{'smtp_sender'},
			  'recipient_maps'  => $config->{recipient_maps},
			  'recipient_limit' => $config->{recipient_limit},

			  'header'          => $header,
			  'body'            => $body,
		      });
    if ($service->error) { Log($service->error); return;}
}


sub _ticket_check
{
    my ($curproc, $args) = @_;    
    my $config = $curproc->{ config };
    my $model  = $config->{ ticket_model };
    my $pkg    = "FML::Ticket::Model::";

    if ($model eq 'toymodel') {
	$pkg .= $model;
    }
    else {
	Log("ticket: unknown model");
	return;
    }

    # fake use() to do "use FML::Ticket::$model;"
    eval qq{ require $pkg; $pkg->import();};
    unless ($@) {
	my $ticket = $pkg->new($curproc, $args);
	if (defined $ticket) {
	    $ticket->assign($curproc, $args);
	    $ticket->update_status($curproc, $args);
	    $ticket->update_db($curproc, $args);
	}
	else {
	    Log("creating ticket object failed");
	}
    }
    else {
	Log($@);
    }
}


1;
