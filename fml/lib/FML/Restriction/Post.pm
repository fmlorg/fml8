#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Post.pm,v 1.26 2006/04/10 13:08:52 fukachan Exp $
#

package FML::Restriction::Post;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Restriction::Post - restricts who is allowed to post/use command mails.

=head1 SYNOPSIS

collection of utility functions used in post routines.

=head1 DESCRIPTION

=head1 METHODS

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


# Descriptions: reject if $sender matches a system account.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_system_special_accounts
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();
    my $match   = $cred->match_system_special_accounts($sender);

    if ($match) {
	$curproc->log("${rule}: $match matches sender address");
	unless ($curproc->restriction_state_get_deny_reason()) {
	    $curproc->restriction_state_set_deny_reason($rule);
	}
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions: [BACKWARD COMPATIBILITY]
#               reject if $sender matches a system account.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_system_accounts
{
    my ($self, $rule, $sender) = @_;
    $self->reject_system_special_accounts($rule, $sender);
}


# Descriptions: reject if $sender matches a spammer.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject_spammer_maps
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();
    my $match   = $cred->is_spammer($sender);

    if ($match) {
	$curproc->log("${rule}: $match matches sender address");
	unless ($curproc->restriction_state_get_deny_reason()) {
	    $curproc->restriction_state_set_deny_reason($rule);
	}
	return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions: permit irrespective of $sender :)
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_anyone
{
    my ($self, $rule, $sender) = @_;

    return("matched", "permit");
}


# Descriptions: permit if $sender is an ML member.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_member_maps
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();

    # Q: the mail sender is an ML member?
    if ($cred->is_member($sender)) {
	# A: Yes, we permit this article to distribute.
	return("matched", "permit");
    }
    else {
	# A: No, deny distribution
	$curproc->logerror("$sender is not an ML member");
	$curproc->logerror( $cred->error() );

	# reply this info in each FML::Process::* module.
	# $curproc->reply_message_nl('error.not_member',
	#			   "you are not a ML member." );
	# $curproc->reply_message( "   your address: $sender" );

	# save reason for later use.
	# XXX the deny reason is first match.
	unless ($curproc->restriction_state_get_deny_reason()) {
	    $curproc->restriction_state_set_deny_reason($rule);
	}

	# XXX "deny ASAP if this method fails." ? NO, wrong!
	# XXX permit_XXX() allows the trial match of another rules.
	# return("matched", "deny");
    }

    return(0, undef);
}


# Descriptions: reject irrespective of $sender.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub reject
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };

    # XXX the deny reason is first match.
    unless ($curproc->restriction_state_get_deny_reason()) {
	$curproc->restriction_state_set_deny_reason($rule);
    }
    return("matched", "deny");
}


=head1 EXTENSION: IGNORE CASE

=head2 ignore

ignore irrespective of other conditions.

=head2 ignore_invalid_request

ignore request if the content is invalid.

=cut


# Descriptions: ignore irrespective of other conditions.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub ignore
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };

    # XXX the deny reason is first match.
    unless ($curproc->restriction_state_get_ignore_reason()) {
	$curproc->restriction_state_set_ignore_reason($rule);
    }
    return("matched", "ignore");
}


# Descriptions: ignore request if the content is invalid.
#               same as ignore() in this module.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub ignore_invalid_request
{
    my ($self, $rule, $sender) = @_;
    $self->ignore();
}


=head1 EXTENSION: ARTICHLE THREAD BASED AUTH

=head2 check_article_thread($rule, $sender)

check references and permit post of this article if it refers this
thread.

=cut


# Descriptions: check references and permit this article
#               if it refers this thread.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: NUM
sub check_article_thread
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $header  = $curproc->incoming_message_header();
    my $reflist = $header->extract_message_id_references() || [];
    my $curtime = time;
    my $_limit  = $config->{ article_post_article_thread_lifetime } || 0;
    my $limit   = $_limit || 3600*24*7;
    my $match   = 0;

  SEARCH_ID:
    for my $id (@$reflist) {
	my $a = { message_id => $id };
	my $r = $header->check_article_message_id($config, $a) || '0';

	# ok if article within $limit (7 days) is referred.
	if ($limit > $curtime - $r) {
	    $match = $curtime - $r;
	    last SEARCH_ID;
	}
    }

    #
    if ($match) {
	$curproc->logdebug("check_article_thread matched. ($match sec old)");
	return("matched", "permit");
    }
    else {
	$curproc->logdebug("check_article_thread unmatched.");
	return(0, undef);
    }
}


=head1 EXTENSION: PGP/GPG AUTH

=head2 check_pgp_signature($rule, $sender)

check PGP signature in message.

=cut

# Descriptions: check PGP signature in message.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: NUM
sub check_pgp_signature
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $file    = $curproc->incoming_message_get_cache_file_path();
    my $match   = 0;
    my $pgp     = undef;

    $self->_setup_pgp_environment();

    eval q{
	use Crypt::OpenPGP;
	$pgp = new Crypt::OpenPGP;
    };
    if ($@) {
	$curproc->logerror("check_pgp_signature need Crypt::OpenPGP.");
	$curproc->logerror($@);
	$self->_reset_pgp_environment();
	return(0, undef);
    }

    my $ret = $pgp->verify(SigFile => $file);
    unless ($pgp->errstr) {
	if ($ret) {
	    $curproc->log("pgp signature found: $ret");
	    $match = 1;
	}
    }
    $self->_reset_pgp_environment();

    if ($match) {
	$curproc->log("check_pgp_signature matched.");
	return("matched", "permit");
    }
    else {
	$curproc->logdebug("check_pgp_signature unmatched.");
	return(0, undef);
    }
}


# Descriptions: modify PGP related environment variables.
#    Arguments: OBJ($self)
# Side Effects: PGP related environment variables modified.
# Return Value: none
sub _setup_pgp_environment
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    # PGP2/PGP5/PGP6
    my $pgp_config_dir = $config->{ article_post_auth_pgp_config_dir };
    $ENV{'PGPPATH'}    = $pgp_config_dir;

    # GPG
    my $gpg_config_dir = $config->{ article_post_auth_gpg_config_dir };
    $ENV{'GNUPGHOME'}  = $gpg_config_dir;
}


# Descriptions: reset PGP related environment variables.
#    Arguments: OBJ($self)
# Side Effects: PGP related environment variables modified.
# Return Value: none
sub _reset_pgp_environment
{
    my ($self) = @_;
    delete $ENV{'PGPPATH'};
    delete $ENV{'GNUPGHOME'};
}


=head1 EXTENSION: MODERATOR

=head2 permit_moderator_member_maps($rule, $sender)

permit if $sender is an ML moderator member.

=cut


# Descriptions: permit if $sender is an ML moderator member.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: ARRAY(STR, STR)
sub permit_moderator_member_maps
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };
    my $cred    = $curproc->credential();

    # Q: the mail sender is an ML moderator member?
    if ($cred->is_moderator_member($sender)) {
	# A: Yes, we permit this article to distribute.
	return("matched", "permit");
    }
    else {
	# A: No, deny distribution
	$curproc->logerror("$sender is not an ML moderator member");
	$curproc->logerror( $cred->error() );

	# save reason for later use.
	# XXX the deny reason is first match.
	unless ($curproc->restriction_state_get_deny_reason()) {
	    $curproc->restriction_state_set_deny_reason($rule);
	}
    }

    return(0, undef);
}


=head2 permit_forward_to_moderator($rule, $sender)

forward the incoming message to moderators.

=cut


# Descriptions: forward the incoming message to moderators.
#    Arguments: OBJ($self) STR($rule) STR($sender)
# Side Effects: none
# Return Value: NUM
sub permit_forward_to_moderator
{
    my ($self, $rule, $sender) = @_;
    my $curproc = $self->{ _curproc };

    $curproc->log("match permit_forward_to_moderator");

    eval q{
	use FML::Moderate;
	my $moderation = new FML::Moderate $curproc;
	$moderation->forward_to_moderator();
    };
    if ($@) { $curproc->logerror($@);}

    # always OK.
    return("matched", "ignore");
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Restriction::Post first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
