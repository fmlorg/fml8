#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Command::resign;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::unsubscribe;
@ISA = qw(FML::Command::unsubscribe);

sub resign
{
    my ($self, $curproc, $args) = @_;
    $self->unsubscribe($curproc, $args);
}

=head1 NAME

FML::Command::resign - alias of "unsubscribe" command

=head1 SYNOPSIS

=head1 DESCRIPTION

all requests are forwarded to C<FML::Command::unsubscribe>.

=head1 AUTHOR

__YOUR_NAME__

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::resign appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
