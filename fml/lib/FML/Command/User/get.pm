#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.22 2004/04/23 04:15:58 fukachan Exp $
#

package FML::Command::User::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Command::SendFile;
@ISA = qw(FML::Command::SendFile);


=head1 NAME

FML::Command::User::get - send back article(s).

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

send back article(s).

=head1 METHODS

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
sub lock_channel { return 'article_spool_modify';}


# Descriptions: check the limit specific to this command.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub check_limit
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->config();
    my $pcb    = $curproc->pcb();
    my $total  = $pcb->get('command', 'get_command_total_num_request') || 0;

    # 1. check the number of article in one command.
    my $limit = $config->{ get_command_request_limit } || 10;
    my $nreq  = $self->num_files_in_send_article_args($curproc, $command_args);
    my $name  = $command_args->{ comname };
    my $_args = { _arg_command => $name, };

    # 1.1 total number of requested articles.
    my $total_num_req = $total + $nreq;
    $pcb->set('command', 'get_command_total_num_request', $total_num_req);

    if ($total_num_req > $limit) {
	$curproc->reply_message_nl('command.exceed_total_request_limit',
				   'total requests exceed limit',
				   $_args);
	$curproc->logerror("get command limit: total=$total_num_req > $limit");
	return $nreq;
    }
    elsif ($nreq > $limit) {
	$curproc->reply_message_nl('command.exceed_request_limit',
				   'requests exceed limit',
				   $_args);
	$curproc->logerror("get command limit: $nreq > $limit");
	return $nreq;
    }
    else {
	return 0;
    }
}


# Descriptions: send articles (filename =~ /^\d+/$) by FML::Command::SendFile.
#               This module is called after
#               FML::Process::Command::_can_accpet_command() already checks the
#               command syntax. $options is raw command as ARRAY_REF such as
#                  $options = [ 'get:3', 1, 100 ];
#               send_article() called below can parse MH style argument.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;

    # call send_article() without checking here but
    # Mail::Message::MH checks and expands the specified targets
    # to HASH_ARRAY of numbers: [ \d+, \d+, ... ].
    $self->send_article($curproc, $command_args);
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

FML::Command::User::get first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
