#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: bye.pm,v 1.5 2002/02/18 14:24:11 fukachan Exp $
#

package FML::Command::Admin::byepriv;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::byeadmin;
@ISA = qw(FML::Command::Admin::byeadmin);


# Descriptions: bye a new admin user
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to byeadmin module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::bye - bye a new member

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

same as C<byeadmin>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::bye appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
