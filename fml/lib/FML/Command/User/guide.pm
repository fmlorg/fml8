#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: guide.pm,v 1.1 2001/10/13 12:17:52 fukachan Exp $
#

package FML::Command::User::guide;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Command::SendFile;
use FML::Log qw(Log LogWarn LogError);
@ISA = qw(FML::Command::SendFile FML::Command::Utils ErrorStatus);


=head1 NAME

FML::Command::User::guide - send back guide file

=head1 SYNOPSIS

=head1 DESCRIPTION

See C<FML::Command> for more details.

=head1 METHODS

=head2 C<process($curproc, $command_args)>

=cut


sub process
{
    my ($self, $curproc, $command_args) = @_;
    my $config = $curproc->{ config };

    $command_args->{ _file_to_send } = $config->{ "guide_file" };
    $self->send_file($curproc, $command_args);
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::guide appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
