
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: mget.pm,v 1.1.1.1 2001/08/26 05:43:10 fukachan Exp $
#

package FML::Command::User::mget;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use ErrorStatus;
use FML::Command::Utils;
use FML::Command::User::get;
@ISA = qw(FML::Command::User::get);

sub process
{
    my ($self, $curproc, $optargs) = @_;
    $self->SUPER::process($curproc, $optargs);
}


=head1 NAME

FML::Command::User::mget - what is this

=head1 SYNOPSIS

forwarded C<FML::Command::User::get>.

=head1 DESCRIPTION

forwarded C<FML::Command::User::get>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::User::mget appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
