#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chaddr.pm,v 1.7 2002/02/18 14:14:52 fukachan Exp $
#

package FML::Command::User::chaddr;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;



use FML::Log qw(Log LogWarn LogError);



=head1 NAME

FML::Command::User::chaddr - change subscriber address

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Firstly apply confirmation before chaddr (change subscriber address).
After confirmation succeeds, chaddr process proceeds.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

if the old address in chaddr arguments is a member, 
try to confirm this request irrespective of "From:" address.

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


# Descriptions: chaddr adapter: confirm before chaddr operation
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: update database for confirmation.
#               prepare reply message.
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_command_prefix };
    my $comname       = $command_args->{ comname };
    my $command       = $command_args->{ command };
    my $sender        = $curproc->{ credential }->sender();

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential;

    # addresses we check and send back confirmation messages to
    my $optargs = {};
    my $x = $command_args->{ command };
    $x =~ s/^.*$comname\s+//;
    my ($old_addr, $new_addr) = split(/\s+/, $x);
    $optargs->{ recipient } = [ $sender, $old_addr, $new_addr ];

    # prompt again (since recipient differs)
    my $prompt  = $config->{ command_prompt } || '>>>';
    $curproc->reply_message("\n$prompt $command", $optargs);

    # if either old or new addresses in chaddr arguments is an ML member, 
    # try to confirm this request irrespective of "From:" address.
    if ($cred->is_member($curproc, { address => $old_addr }) ||
	$cred->is_member($curproc, { address => $new_addr })) {
	Log("chaddr request, try confirmation");

	use FML::Confirm;
	my $confirm = new FML::Confirm {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'chaddr',
	    address   => $sender,
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm', '', $optargs);
	$curproc->reply_message("\n$id\n", $optargs);
    }
    # try confirmation before chaddr
    else {
	$curproc->reply_message_nl('error.not_member', '', $optargs);
	croak("not member");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::chaddr appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
