#-*- perl -*-
#
#  Copyright (C) 2002 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: on.pm,v 1.1 2002/07/22 15:39:55 tmu Exp $
#

package FML::Command::User::on;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::User::on - on

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

Firstly apply confirmation before on.
After confirmation succeeds, on process proceeds.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

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


# Descriptions: on adapter.
#               we confirm it before real on process.
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
    my $command       = $command_args->{ command };
    my $address       = $curproc->{ credential }->sender();

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential $curproc;

    # if not member, on request is wrong.
    unless ($cred->is_member($address)) {
	$curproc->reply_message_nl('error.not_member');
	LogError("on request from not member");
	croak("not member");
	return;
    }

    # if already recipient, on request is wrong.
    if ($cred->is_recipient($address)) {
	$curproc->reply_message_nl('error.already_recipient',
				   'already recipient',
				   {
				       _arg_address => $address
				   });
	croak("already recipient");
    }
    # if not, try confirmation before on
    else {
	Log("change on mode, try confirmation");
	use FML::Confirm;
	my $confirm = new FML::Confirm {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'on',
	    address   => $address,
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm');
	$curproc->reply_message("\n$id\n");
    }
}


=head1 AUTHOR

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::on appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
