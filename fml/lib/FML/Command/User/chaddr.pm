#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.28 2004/02/04 15:03:27 fukachan Exp $
#

package FML::Command::User::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::User::chaddr - change subscribed address

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Firstly, apply confirmation before chaddr (change subscribed address)
processed. After confirmation succeeds, chaddr process proceeds.

=head1 METHODS

=head2 process($curproc, $command_args)

If either old or new addresses in chaddr arguments is an ML member,
try to confirm this request. The confirmation is returned to "From:"
address in the mail header, "Reply-To" is ignored.

=cut


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: need lock or not
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: chaddr adapter: confirm before real chaddr operation.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update database for confirmation.
#               prepare reply message.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->{ credential };

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, one of member_maps is under admin_member_maps.
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $comname       = $command_args->{ comname };
    my $command       = $command_args->{ command };
    my $sender        = $cred->sender();

    # cheap sanity checks
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    # exatct match as could as possible.
    my $compare_level = $cred->get_compare_level();
    $cred->set_compare_level( 100 );

    # addresses we check and send back confirmation messages to
    my $optargs = {};
    my $x = $command_args->{ command };
    $x =~ s/^.*$comname\s+//;
    my ($old_addr, $new_addr) = split(/\s+/, $x);
    $optargs->{ recipient } = [ $sender, $old_addr, $new_addr ];

    # simple checks.
    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $old_addr)) {
	$curproc->logerror("chaddr: unsafe address <$old_addr>");
	croak("chaddr: unsafe address");
    }
    unless ($safe->regexp_match('address', $new_addr)) {
	$curproc->logerror("chaddr: unsafe address <$new_addr>");
	croak("chaddr: unsafe address");
    }

    # prompt again (since recipient differs)
    my $prompt = $config->{ command_mail_reply_prompt } || '>>>';
    $curproc->reply_message("\n$prompt $command", $optargs);

    # if either old or new addresses in chaddr arguments is an ML member,
    # try to confirm this request irrespective of "From:" address.
    # 1. request from $old_addr : $old_addr (member now) -> $new_addr
    # 2. request from $new_addr : $old_addr -> $new_addr (member now)
    if ($cred->is_member($old_addr) || $cred->is_member($new_addr)) {
	$curproc->log("chaddr request, try confirmation");

	# XXX-TODO: should be FML::Confirm { ... address => [ @addr ] } ?
	use FML::Confirm;
	my $confirm = new FML::Confirm $curproc, {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'chaddr',
	    address   => "$old_addr $new_addr",
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm', '', $optargs);
	$curproc->reply_message("\n$id\n", $optargs);
    }
    # try confirmation before chaddr
    else {
	$curproc->reply_message_nl('error.not_member', '', $optargs);
	$cred->set_compare_level( $compare_level );
	croak("not member");
    }

    $cred->set_compare_level( $compare_level );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::chaddr first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
