#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: add.pm,v 1.5 2001/04/03 09:45:41 fukachan Exp $
#

package FML::Command::add;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::subscribe;
@ISA = qw(FML::Command::subscribe);

sub add
{
    my ($self, $curproc, $args) = @_;
    $self->SUPER::subscribe($curproc, $args);
}

=head1 NAME

FML::Command::add - add a new member

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

FML::Command::add appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
