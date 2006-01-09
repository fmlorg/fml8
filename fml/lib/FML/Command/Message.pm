#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Message.pm,v 1.1 2006/01/07 14:43:25 fukachan Exp $
#

package FML::Command::Message;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::Message - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

constructor.

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


=head2 send_confirmation($curproc, $command_args, $confirm, $sc_args)

send back confirmation message.

1. if $XXX_command_auth_type == confirmation,
1.1 send back confirmation to address (From:).

2. if $XXX_command_auth_type == manual,
2.1 notify "forwarded request to maintainer(s)." to sender.
2.2 notify request to maintainer(s).

=cut


# Descriptions: send back confirmation message.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
#               OBJ($confirm) HASH_REF($sc_args)
# Side Effects: messages sent.
# Return Value: none
sub send_confirmation
{
    my ($self, $curproc, $command_args, $confirm, $sc_args) = @_;
    my $config  = $curproc->config();
    my $id      = $confirm->assign_id;
    my $command = $sc_args->{ command } || "";
    my $rm_args = $sc_args->{ rm_args } || {};
    my $varname = "${command}_command_auth_type";
    my $mode    = $config->{ $varname } || 'confirmation';

    # 1. send back confirmation to address (From:) by default.
    # if XXX_command_auth_type == confirmation
    #    send back confirmation to $sender.
    #    $sender send back again the confirmation to fml8.
    #    fml8 do actual subscription et.al. automatically.
    #    So, $maintainer do nothing.
    if ($mode eq 'confirmation') {
	$curproc->reply_message_nl('command.confirm', "", $rm_args);
	$curproc->reply_message("\n$id\n", $rm_args);
    }
    # 2. forward request to maintainer(s) "without confirmation".
    # if XXX_command_auth_type == manual
    #    forward the request to $maintainer.
    #    The maintainer do actual subscription et.al. automatically.
    #    So, fml8 do nothing.
    elsif ($mode eq 'manual') {
	my $msg        = $curproc->incoming_message();
	my $maintainer = $config->{ maintainer };
	my $_rm_args   = {
	    recipient    => $maintainer,
	    _arg_command => $command,
	};
	my $default    = "send back the following confirmation.";

	# 2.1 notify "forwarded request to maintainer(s)." to sender.
	$curproc->reply_message_nl('command.forward_request_to_admin',
				   "",
				   $rm_args);

	# 2.2 notify request to maintainer(s).
	$curproc->reply_message_nl('command.receive_request', "", $_rm_args);
	$curproc->reply_message_nl('command.confirm', $default, $_rm_args);
	$curproc->reply_message("\n$id\n", $_rm_args);
	$curproc->reply_message($msg, $_rm_args);
    }
    # 3. fatal error if neither of automatic nor manual.
    else {
	$curproc->logerror("unknown operation mode");
	croak("unknown operation mode");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Message appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
