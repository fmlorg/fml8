#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: remove.pm,v 1.1.1.1 2001/08/26 05:43:10 fukachan Exp $
#

package FML::Command::User::remove;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Utils;
use FML::Command::User::unsubscribe;
@ISA = qw(FML::Command::User::unsubscribe use FML::Command::Utils);

sub process
{
    my ($self, $curproc, $optargs) = @_;
    $self->SUPER::unsubscribe($curproc, $optargs);
}


=head1 NAME

FML::Command::User::remove - remove the specified member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::remove appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
