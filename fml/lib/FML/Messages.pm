#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Messages;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;


=head1 NAME

FML::Messages - manipulate fml system messages

=head1 SYNOPSIS

NOT YET IMPLEMENTED

=head1 DESCRIPTION

NOT YET IMPLEMENTED

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    return bless {}, $type;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Messages appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
