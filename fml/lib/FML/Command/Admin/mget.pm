#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mget.pm,v 1.9 2004/01/02 14:42:42 fukachan Exp $
#

package FML::Command::Admin::mget;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::get;
@ISA = qw(FML::Command::Admin::get);


# Descriptions: get file(s) in $ml_home_dir
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forwarded to get module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    $self->SUPER::process($curproc, $command_context);
}


=head1 NAME

FML::Command::Admin::mget - get file(s) in $ml_home_dir

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::get>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::mget first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
