#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: add.pm,v 1.9 2004/01/02 14:42:42 fukachan Exp $
#

package FML::Command::Admin::add2member;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::addmember;
@ISA = qw(FML::Command::Admin::addmember);


# Descriptions: add user as only member
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to addmember module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}

=head1 NAME

FML::Command::Admin::add - add a new member (member only)

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::addmember>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::add first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
