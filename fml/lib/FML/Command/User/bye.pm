#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: bye.pm,v 1.8 2001/07/15 12:03:37 fukachan Exp $
#

package FML::Command::User::bye;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

FML::Command::Utils;
use FML::Command::unsubscribe;
@ISA = qw(FML::Command::unsubscribe FML::Command::Utils);

sub process
{
    my ($self, $curproc, $optargs) = @_;
    $self->SUPER::process($curproc, $optargs);
}


=head1 NAME

FML::Command::bye - remove the specified member

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

FML::Command::bye appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
