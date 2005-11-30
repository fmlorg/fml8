#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: unsubscribe.pm,v 1.34 2005/08/11 04:07:33 fukachan Exp $
#

package FML::Command::User::unsubscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


=head1 NAME

FML::Command::User::unsubscribe - unsubscribe request handling.

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Firstly apply confirmation before the real unsubscribe process.
After confirmation succeeds, unsubcribe process proceeds.

=head1 METHODS

=head2 process($curproc, $command_args)

=cut


# Descriptions: constructor.
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


# Descriptions: need lock or not.
#    Arguments: none
# Side Effects: none
# Return Value: NUM( 1 or 0)
sub need_lock { 1;}


# Descriptions: lock channel.
#    Arguments: none
# Side Effects: none
# Return Value: STR
sub lock_channel { return 'command_serialize';}


# Descriptions: unsubscribe adapter: confirm before unsubscribe.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update database for confirmation.
#               prepare reply message.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();
    my $cred   = $curproc->credential();

    # XXX We should always add/rewrite only $primary_*_map maps via
    # XXX command mail, CUI and GUI.
    # XXX Rewriting of maps not $primary_*_map is
    # XXX 1) may be not writable.
    # XXX 2) ambigous and dangerous
    # XXX    since the map is under controlled by other module.
    # XXX    for example, $member_maps contains different classes.
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $command       = $command_args->{ command };
    my $options       = $command_args->{ options };
    my $cui_options   = $curproc->command_line_cui_specific_options() || {};
    my $address       = $cui_options->{ 'send-to' } || $cred->sender();

    # cheap sanity checks
    croak("\$member_map unspecified")    unless $member_map;
    croak("\$recipient_map unspecified") unless $recipient_map;
    croak("\$address unspecified")       unless $address;

    # XXX extension: fml --allow-send-message or fml --allow-reply-message
    unless ($cred->sender()) {
	if ($curproc->is_allow_reply_message()) {
	    $cred->set_sender($address);
	}
    }

    # exact match as could as possible.
    my $compare_level = $cred->get_compare_level();
    $cred->set_compare_level( 100 );

    # if not member, unsubscriber request is wrong.
    unless ($cred->is_member($address)) {
	$cred->set_compare_level( $compare_level );
	$curproc->reply_message_nl('error.not_member');
	$curproc->logerror("unsubscribe request from not member");
	croak("unsubscribe request from not member");
    }
    # try confirmation before unsubscribe
    else {
	$curproc->log("unsubscribe request, try confirmation");

        use FML::Confirm;
	my $confirm = new FML::Confirm $curproc, {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'unsubscribe',
	    address   => $address,
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm');
	$curproc->reply_message("\n$id\n");
    }

    $cred->set_compare_level( $compare_level );
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::unsubscribe first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
