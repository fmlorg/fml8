#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: signoff.pm,v 1.2 2001/08/26 07:59:03 fukachan Exp $
#

package FML::Command::User::signoff;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Utils;
use FML::Command::User::unsubscribe;
@ISA = qw(FML::Command::User::unsubscribe use FML::Command::Utils);

sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::unsubscribe($curproc, $command_args);
}


=head1 NAME

FML::Command::User::signoff - signoff the specified member

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::signoff appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
