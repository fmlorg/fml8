#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: add.pm,v 1.5 2002/02/18 14:24:11 fukachan Exp $
#

package FML::Command::Admin::addpriv;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::addadmin;
@ISA = qw(FML::Command::Admin::addadmin);


# Descriptions: add a new admin user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to addadmin module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::add - add a new member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

same as C<addadmin>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::add appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
