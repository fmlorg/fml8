#-*- perl -*-
#
# Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#          All rights reserved.
#
# $FML: Digest.pm,v 1.18 2004/03/13 06:03:24 fukachan Exp $
#

package FML::Process::Digest;

use vars qw($debug @ISA @EXPORT @EXPORT_OK);
use strict;
use Carp;

use FML::Config;
use FML::Process::Kernel;
@ISA = qw(FML::Process::Kernel);


=head1 NAME

FML::Process::Digest -- digest delivery.

=head1 SYNOPSIS

   use FML::Process::Digest;
   ...

See L<FML::Process::Flow> for details of the fml flow.

=head1 DESCRIPTION

C<FML::Process::Flow::ProcessStart($obj, $args)> drives the fml flow
where C<$obj> is the object C<FML::Process::$module::new()> returns.

=head1 METHOD

=head2 new($args)

create C<FML::Process::Digest> object.
C<$curproc> is the object C<FML::Process::Kernel> returns but
we bless it as C<FML::Process::Digest> object again.

=cut


# Descriptions: constructor.
#               sub class of FML::Process::Kernel
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ(FML::Process::Digest)
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
fix @INC.

=cut


# Descriptions: prepare miscellaneous work before the main routine starts.
#               adjust ml_* and load configuration files. fix @INC.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'digest_prepare_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->resolve_ml_specific_variables();
    $curproc->load_config_files();
    $curproc->fix_perl_include_path();
    $curproc->scheduler_init();

    unless ($config->yes('use_article_digest_function')) {
	$curproc->logerror("use of digest_program prohibited");
	exit(0);
    }

    $eval = $config->get_hook( 'digest_prepare_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 verify_request($args)

set up the mail sender.

=cut


# Descriptions: set up the mail sender.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request
{
    my ($curproc, $args) = @_;
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };

    my $eval = $config->get_hook( 'digest_verify_request_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    # set sender against further errors
    $curproc->{'credential'}->set( 'sender', $maintainer );

    $eval = $config->get_hook( 'digest_verify_request_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }
}


=head2 run($args)

Firstly it locks (giant lock) the current process.

If the mail sender is one of our mailing list member,
we can digest the mail as an article.
If not, we inform "you are not a member" which is sent by
C<inform_reply_messages()> in C<FML::Process::Kernel>.

Lastly we unlock the current process.

=cut


# Descriptions: the main routine, kick off _digest().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: distribution of articles.
#               See _digest() for more details.
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;
    my $config     = $curproc->config();
    my $maintainer = $config->{ maintainer };
    my $sender     = $curproc->{'credential'}->{'sender'};

    my $eval = $config->get_hook( 'digest_run_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->lock();
    unless ($curproc->is_refused()) {
	$curproc->_digest();
    }
    else {
	$curproc->logerror("ignore this request.");
    }
    $curproc->unlock();

    $eval = $config->get_hook( 'digest_run_end_hook' );
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

   For example, digest of elena ML
   $0 /var/spool/ml/elena

_EOF_
}


=head2 finish($args)

Finalize the current process.
If needed, we send back error messages to the mail sender.

=cut


# Descriptions: queue flush.
#               return error messages et. al if needed.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: queue flush
# Return Value: none
sub finish
{
    my ($curproc, $args) = @_;
    my $config = $curproc->config();

    my $eval = $config->get_hook( 'digest_finish_start_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

    $curproc->inform_reply_messages();
    $curproc->queue_flush();

    $eval = $config->get_hook( 'digest_finish_end_hook' );
    if ($eval) { eval qq{ $eval; }; $curproc->logwarn($@) if $@; }

}


# Descriptions: primitive digest delivery.
#    Arguments: OBJ($curproc)
# Side Effects: update digest sequence.
# Return Value: none
sub _digest
{
    my ($curproc) = @_;

    use FML::Digest;
    my $digest = new FML::Digest $curproc;
    my $aid    = $digest->get_article_id();
    my $did    = $digest->get_digest_id();

    # run digest proceess if article(s) not to send found.
    if ($aid > $did) {
	$did++; # start = last digest id + 1
	my $range = "$did-$aid";

	# XXX-TODO: $range = "100-200" -> $range = [ 100, 101, ... ]; ?
	# create multipart of articles as a digest.
	$digest->create_multipart_message({ range => $range });

	# update the last digest id for the next digest delivery.
	# e.g. seq-digest in each ml home directory.
	$digest->set_digest_id($aid);
    }
    else {
	$curproc->log("no articles to send as digest");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2000,2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Digest first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
