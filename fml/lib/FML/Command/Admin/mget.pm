#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mget.pm,v 1.6 2002/04/07 05:08:24 fukachan Exp $
#

package FML::Command::Admin::mget;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use FML::Command::Admin::get;
@ISA = qw(FML::Command::Admin::get);


# Descriptions: get file(s) in $ml_home_dir
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: forwarded to get module
# Return Value: none
sub process
{
    my ($self, $curproc, $command_args) = @_;
    $self->SUPER::process($curproc, $command_args);
}


=head1 NAME

FML::Command::Admin::mget - get file(s) in $ml_home_dir

=head1 SYNOPSIS

See C<FML::Command> for more details.

=head1 DESCRIPTION

an alias of C<FML::Command::Admin::get>.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Admin::mget first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
