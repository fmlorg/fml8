#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: unsubscribe.pm,v 1.21 2003/08/23 07:24:44 fukachan Exp $
#

package FML::Command::User::unsubscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::User::unsubscribe - unsubscribe request handling

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Firstly apply confirmation before the real unsubscribe process.
After confirmation succeeds, unsubcribe process proceeds.

=head1 METHODS

=head2 process($curproc, $command_args)

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


# Descriptions: unsubscribe adapter: confirm before unsubscribe
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update database for confirmation.
#               prepare reply message.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->config();

    # XXX-TODO: wrong to handle only primary_*_map in deluser phase.
    # XXX-TODO: we should check all maps?
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $command       = $command_args->{ command };
    my $address       = $curproc->{ credential }->sender();

    # cheap sanity checks
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential $curproc;

    # exatct match as could as possible.
    $cred->set_compare_level( 100 );

    # if not member, unsubscriber request is wrong.
    unless ($cred->is_member($address)) {
	$curproc->reply_message_nl('error.not_member');
	$curproc->logerror("unsubscribe request from not member");
	croak("unsubscribe request from not member");
    }
    # try confirmation before unsubscribe
    else {
	$curproc->log("unsubscribe request, try confirmation");

        use FML::Confirm;
	my $confirm = new FML::Confirm {
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
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::unsubscribe first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
