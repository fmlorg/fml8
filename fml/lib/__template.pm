#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::__HERE_IS_YOUR_MODULE_NAME__;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 NAME

FML::__HERE_IS_YOUR_MODULE_NAME__.pm - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASSES

=head1 METHODS

=item C<new()>

... what is this ...

=head1 AUTHOR

__YOUR_NAME__

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__HERE_IS_YOUR_MODULE_NAME__.pm appeared in fml5.

=cut

1;
