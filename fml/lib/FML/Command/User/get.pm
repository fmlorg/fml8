#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.26 2006/04/16 06:33:36 fukachan Exp $
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
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub check_limit
{
    my ($self, $curproc, $command_context) = @_;
    my $config = $curproc->config();
    my $pcb    = $curproc->pcb();

    # 1. check the number of article in one command.
    my $total = $pcb->get('command', 'get_command_request_total') || 0;
    my $nreq  = $self->num_files_in_send_article_args($curproc,
						      $command_context);
    my $request_total = $total + $nreq;
    $pcb->set('command', 'get_command_request_total', $request_total);

    # XXX-TODO: same limit value ?
    my $limit   = $config->{ get_command_request_limit } || 10;
    my $comname = $command_context->get_cooked_command();
    my $rm_args = { _arg_command => $comname, };
    if ($request_total > $limit) {
	$curproc->reply_message_nl('command.exceed_total_request_limit',
				   'total requests exceed limit',
				   $rm_args);
	$curproc->logerror("get command limit: total=$request_total > $limit");
	return $nreq;
    }
    elsif ($nreq > $limit) {
	$curproc->reply_message_nl('command.exceed_request_limit',
				   'requests exceed limit',
				   $rm_args);
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
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;

    # call send_article() without checking here but
    # Mail::Message::MH checks and expands the specified targets
    # to HASH_ARRAY of numbers: [ \d+, \d+, ... ].
    $self->send_article($curproc, $command_context);
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::get first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
