#-*- perl -*-
#
#  Copyright (C) 2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: pass.pm,v 1.5 2003/12/31 03:49:17 fukachan Exp $
#

package FML::Command::Admin::pass;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


use FML::Command::Admin::password;
@ISA = qw(FML::Command::Admin::password);


# Descriptions: authenticate remote admin password
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forward request to password module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::Admin::pass - authenticate remote admin password

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

authenticate remote admin password.
an alias of C<FML::Command::Admin::password>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::pass first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
