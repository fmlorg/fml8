#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: subscribe.pm,v 1.6 2001/10/14 00:32:30 fukachan Exp $
#

package FML::Command::User::subscribe;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::User::subscribe - subscribe a new member

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config        = $curproc->{ config };
    my $member_map    = $config->{ primary_member_map };
    my $recipient_map = $config->{ primary_recipient_map };
    my $cache_dir     = $config->{ db_dir };
    my $keyword       = $config->{ confirm_keyword };
    my $command       = $command_args->{ command };
    my $address       = $curproc->{ credential }->sender();

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential;

    # if already member, subscriber request is wrong.
    if ($cred->is_member($curproc, { address => $address })) {
	$curproc->reply_message_nl('error.already_member',
				   'already member',
				   {
				       _arg_address => $address
				   });
	croak("already member");
    }
    # if not, try confirmation before subscribe
    else {
	Log("new subscriber, try confirmation");
	use FML::Confirm;
	my $confirm = new FML::Confirm {
	    keyword   => $keyword,
	    cache_dir => $cache_dir,
	    class     => 'subscribe',
	    address   => $address,
	    buffer    => $command,
	};
	my $id = $confirm->assign_id;
	$curproc->reply_message_nl('command.confirm');
	$curproc->reply_message("\n$id\n");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::subscribe appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
