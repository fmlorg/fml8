#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: NIS.pm,v 1.14 2001/05/04 14:32:34 fukachan Exp $
#

package IO::Adapter::NIS;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::Array;

@ISA = qw(IO::Adapter::Array);


=head1 NAME

IO::Adapter::NIS - NIS map operations

=head1 SYNOPSIS

    $map = 'nis.group:fml';

    use IO::Adapter;
    $obj = new IO::Adapter $map;
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

=head1 DESCRIPTION

fake IO operations to
NIS (Network Information System, its old name is Yellow Page).
See L<IO::Adapter::Array> for more details.

C<CAUTION: this map is read only>.

=head1 METHODS

See L<IO::Adapter::Array>.

=head2 C<configure($obj)>

Configure $obj for array IO emulation.

=cut

sub configure
{
    my ($self, $me) = @_;
    my ($type) = ref($self) || $self;

    # emulate an array on memory
    my $key        = $me->{_name};
    my (@x)        = split(/:/, `ypmatch $key group.byname`);
    my (@elements) = split ',', $x[3];
    $me->{_array_reference} = \@elements;
}


=head1 SEE ALSO

L<IO::Adapter::Array>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::NIS appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
