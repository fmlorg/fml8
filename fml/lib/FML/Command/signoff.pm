#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: signoff.pm,v 1.2 2001/06/17 08:57:10 fukachan Exp $
#

package FML::Command::signoff;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::unsubscribe;
@ISA = qw(FML::Command::unsubscribe);

sub signoff
{
    my ($self, $curproc, $optargs) = @_;
    $self->SUPER::unsubscribe($curproc, $optargs);
}


=head1 NAME

FML::Command::signoff - signoff the specified member

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::signoff appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
