#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: chpass.pm,v 1.2 2004/01/01 08:41:33 fukachan Exp $
#

package FML::Command::Admin::chpass;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::changepassword;
@ISA = qw(FML::Command::Admin::changepassword);


# Descriptions: change remote administrator password.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to password module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::Admin::chpass - change remote administrator password

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

change remote administrator password.
an alias of C<FML::Command::Admin::changepassword>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::chpass first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
