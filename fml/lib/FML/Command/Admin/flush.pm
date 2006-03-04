#-*- perl -*-
#
#  Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: flush.pm,v 1.1 2004/05/19 13:48:20 fukachan Exp $
#

package FML::Command::Admin::flush;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::flushq;
@ISA = qw(FML::Command::Admin::flushq);


# Descriptions: subscribe user
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: forward request to subscribe module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_context) = @_;
    $self->SUPER::process($curproc, $command_context);
}


=head1 NAME

FML::Command::Admin::flush - flush mail queue

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::flush appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
