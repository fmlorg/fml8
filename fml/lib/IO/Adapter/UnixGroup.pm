#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::Adapter::UnixGroup;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::Array;

@ISA = qw(IO::Adapter::Array);

sub configure
{
    my ($self, $me) = @_;
    my ($type) = ref($self) || $self;

    # emulate an array on memory
    my (@x)       = getgrnam( $me->{_name} );
    my (@members) = split ' ', $x[3];
    $me->{_array_reference} = \@members;
}



=head1 NAME

IO::Adapter::UnixGroup.pm - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASSES

=head1 METHODS

=item C<new()>

... what is this ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::UnixGroup.pm appeared in fml5.

=cut

1;
