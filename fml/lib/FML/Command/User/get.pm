#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get.pm,v 1.9 2002/02/13 10:41:17 fukachan Exp $
#

package FML::Command::User::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;



use FML::Command::SendFile;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::SendFile);

=head1 NAME

FML::Command::User::get - send back articles

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

send back articles.

=head1 METHODS

=head2 C<process()>

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
    $self->send_article($curproc, $command_args);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::User::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
