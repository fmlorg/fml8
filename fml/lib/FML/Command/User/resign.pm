#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: resign.pm,v 1.8 2001/08/26 04:13:40 fukachan Exp $
#

package FML::Command::User::resign;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Utils;
use FML::Command::unsubscribe;
@ISA = qw(FML::Command::unsubscribe use FML::Command::Utils);

sub process
{
    my ($self, $curproc, $optargs) = @_;
    $self->unsubscribe($curproc, $optargs);
}

=head1 NAME

FML::Command::resign - alias of "unsubscribe" command

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

all requests are forwarded to C<FML::Command::unsubscribe>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::resign appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
