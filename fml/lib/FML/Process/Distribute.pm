#!/usr/local/bin/perl -w
#-*- perl -*-
#
# Copyright (C) 2000,2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Distribute.pm,v 1.53 2001/11/25 03:13:50 fukachan Exp $
#

package FML::Process::Distribute;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Process::Kernel;
use FML::Log qw(Log LogWarn LogError);
use FML::Config;

@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Distribute -- fml5 article distributer library.

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
we bless it as C<FML::Process::Distribute> object.

=cut

# Descriptions: constructor.
#               sub class of FML::Process::Kernel
#    Arguments: $self $args
# Side Effects: none
# Return Value: FML::Process::Distribute object
sub new
{
    my ($self, $args) = @_;
    my $type    = ref($self) || $self;
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare($args)>

forward the request to the base class.

=cut

# Descriptions: prepare miscellaneous work before the main routine starts
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($self, $args) = @_;
    $self->SUPER::prepare($args);
}


=head2 C<verify_request($args)>

check the mail sender and the mail loop possibility.

=cut

# Descriptions: verify the mail sender and others
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    $curproc->verify_sender_credential();
    $curproc->simple_loop_check();
}


=head2 C<run($args>)

Firstly it locks (giant lock) the current process.

If the mail sender is one of our mailing list member,
we can distribute the mail as an article.
If not, we inform "you are not a member" which is sent by
C<inform_reply_messages()> in C<FML::Process::Kernel>.

Lastly we unlock the current process.

=cut

# Descriptions: the main routine
#    Arguments: $self $args
# Side Effects: distribution of articles.
#               See _distribute() for more details.
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;

    $curproc->lock();
    {
	if ($curproc->permit_post($args)) {
	    $curproc->_distribute($args);
	}
	else {
	    Log("deny article submission");
	}
    }
    $curproc->unlock();
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

   For example, distribute of elena ML
   $0 /var/spool/ml/elena

_EOF_
}


=head2 C<finish($args)>

Finalize the current process.
If needed, we send back error messages to the mail sender.

=cut

# Descriptions: clean up in the end of the curreen process
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;

    $curproc->inform_reply_messages();
    $curproc->queue_flush();
}


# Descriptions: the top level routine to drive the article spooling and
#               distribution.
#                  $article->header_rewrite();
#                  $article->increment_id();
#                  $article->spool();
#    Arguments: $self $args
# Side Effects: header rewrite
#               the article sequence number is incremanted
#               article spooling. 
# Return Value: none
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
	my $ha_msg = $curproc->{ article }->{ body }->get_data_type_list;
	for (@$ha_msg) { Log($_);}
    }

    # thread system checks the message before header rewritings.
    $curproc->_thread_check($args) if $config->yes('use_thread_track');

    # header operations
    # XXX we need $curproc->{ article }, which is prepared above.
    $curproc->_header_rewrite({ id => $id });

    # spool in the article before delivery
    $ah->spool_in($id);

    # delivery starts !
    $curproc->_deliver_article($args);
}


# Descriptions: build and return FML::Article object
#    Arguments: $self $args
# Side Effects: none
# Return Value: FML::Article object
sub _prepare_article
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
#    Arguments: $self $args
# Side Effects: $curproc->{ article }->{ header } is rewritten
# Return Value: none
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


# Descriptions: deliver the article
#    Arguments: $self $args
# Side Effects: smtp logging
# Return Value: none
sub _deliver_article
{
    my ($curproc, $args) = @_;

    my $config  = $curproc->{ config };               # FML::Config   object
    my $message = $curproc->{ article }->{ message }; # Mail::Message object
    my $header  = $curproc->{ article }->{ header };  # FML::Header   object
    my $body    = $curproc->{ article }->{ body };    # Mail::Message object
	
    unless ( $config->yes( 'use_article_delivery' ) ) {
	return;
    }

    # SMTP-FROM is a must!
    unless ( $config->{'maintainer'} ) {
	Log("not delivery for undefined \$maintainer");
	return;
    }

    # distribute article
    use Mail::Delivery;

    my $fp  = sub { Log(@_);}; # pointer to the log function
    my $sfp = sub { my ($s) = @_; print $s; print "\n" if $s !~ /\n$/o;};

    { # debug
	my $dir = $config->{ smtp_log_dir };
	use File::Utils qw(mkdirhier);
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

    # start delivery
    my $service = new Mail::Delivery {
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

			  'message'         => $message,
		      });
    if ($service->error) { Log($service->error); return;}
}


# Descriptions: the top level interface to drive thread tracking system
#    Arguments: $self $args
# Side Effects: update thread information
# Return Value: none
sub _thread_check
{
    my ($curproc, $args) = @_;    
    my $config = $curproc->{ config };
    my $pcb    = $curproc->{ pcb };
    my $myname = $curproc->myname();

    my $ml_name       = $config->{ ml_name };
    my $thread_db_dir = $config->{ thread_db_dir };
    my $spool_dir     = $config->{ spool_dir };
    my $article_id    = $pcb->get('article', 'id');
    my $ttargs        = {
	myname      => $myname,
	logfp       => \&Log,
	fd          => \*STDOUT,
	db_base_dir => $thread_db_dir,
	ml_name     => $ml_name,
	spool_dir   => $spool_dir,
	article_id  => $article_id,
    };

    my $msg = $curproc->{ article }->{ message };

    eval q{ 
	use Mail::ThreadTrack;
	my $thread = new Mail::ThreadTrack $ttargs;
	$thread->analyze($msg);
    };

    Log($@) if $@;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Process::Distribute appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
