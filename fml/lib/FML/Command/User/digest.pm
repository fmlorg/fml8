#-*- perl -*-
#
#  Copyright (C) 2002 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: on.pm,v 1.4 2002/09/22 14:56:48 fukachan Exp $
#

package FML::Command::User::digest;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);


=head1 NAME

FML::Command::User::digest - digest

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

digest mode change on or off

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


# Descriptions: digest on or off adapter.
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
    my $mode          = "";

    # fundamental check
    croak("\$member_map is not specified")    unless $member_map;
    croak("\$recipient_map is not specified") unless $recipient_map;

    use FML::Credential;
    my $cred = new FML::Credential $curproc;

    # if not member, on request is wrong.
    unless ($cred->is_member($address)) {
	$curproc->reply_message_nl('error.not_member');
	LogError("digest request from not member");
	croak("not member");
	return;
    }

    if ($command =~ /digest\s+(\w+)/)
    {
    	$mode = $1;
    }

    $command_args->{ command_data } = $address;
    Log("change digest mode $command $mode");
    use FML::Command::Admin::digest;
    my $obj = new FML::Command::Admin::digest $curproc,$command_args;
    if($mode eq "on") {
	$obj->_on($curproc, $command_args);
    }
    if($mode eq "off") {
	$obj->_off($curproc, $command_args);
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2002 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::digest first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
