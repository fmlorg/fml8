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


sub run
{
    my ($curproc, $args) = @_;

    $curproc->verify_sender_credential();

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

    # use FML::Debug; FML::Debug->show_structure( $curproc ); # XXX DEBUG

    # create aritcle to distribute
    use FML::Article;
    my $article = new FML::Article $curproc;

    # spool in
    my $id = $article->gen_article_id;
    $article->spool_in( $id );

    # distribute article
    use Netlib::SMTP;
    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};
    my $service = new Netlib::SMTP {
	log_function       => $fp,
	smtp_log_function  => $sfp,
	socket_timeout     => 2,     # XXX 2 for debug but 10 by default
    };
    if ($service->error) { Log($service->error); return;}

    $article    = $curproc->{ article };
    my $body    = $article->{ body };    # FML::Body -> Netlib::Messages
    my $header  = $article->{ header };  # FML::Header object
    my $config  = $curproc->{ config };  # FML::Config object

    $service->deliver(
		      {
			  'mta'             => $config->{'mta'},

			  'smtp_sender'     => 'rudo',
			  'recipient_maps'  => $config->{recipient_maps},
			  'recipient_limit' => $config->{recipient_limit},

			  'header'          => $header,
			  'body'            => $body,
		      });
    if ($service->error) { Log($service->error); return;}
}



=head1 NAME

distribute -- fml5 article distributer program.

=head1 SYNOPSIS

   distribute [-d] config.cf

=head1 DESCRIPTION

libexec/fml.pl, the wrapper, executes this program. For example, The
incoming mail to elena@fml.org kicks off libexec/distribute via
libexec/fml.pl, whereas mail to elena-ctl@fml.org kicks off
libexec/command finally.

   incoming_mail =>
      elena@fml.org       => fml.pl => libexec/distribute
      elena-ctl@fml.org   => fml.pl => libexec/command
      elena-admin@fml.org => forwarded to administrator(s)
                                  OR
                          => libexec/mead

C<-d>
    debug on.

=head1 FLOW AROUND COMPONENTS

   |  <=> FML::BaseSystem
   |      load configuration files
   |      start logging service
   |
   |  STDIN                     => FML::Parse
   |  $CurProc->{'incoming_mail'} <=
   |  $CurProc->{'credential'}
   | 
   |  (lock)
   |  prepare article
   |  $CurProc->{'article'} is spooled in.
   |  $CurProc->{'article'}    <=> Service::SMTP
   |  (unlock)
   V

=cut

1;
