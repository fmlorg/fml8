#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: NIS.pm,v 1.23 2004/01/24 09:00:53 fukachan Exp $
#

package IO::Adapter::NIS;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::Array;

@ISA = qw(IO::Adapter::Array);


=head1 NAME

IO::Adapter::NIS - NIS map operations.

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

This class inherits C<IO::Adapter::Array>.
See L<IO::Adapter::Array>.

=head2 configure($obj)

Configure $obj for array IO emulation.

=cut


# Descriptions: initialize NIS specific configuration.
#    Arguments: OBJ($self) HASH_REF($me)
# Side Effects: none
# Return Value: ARRAY_REF
sub configure
{
    my ($self, $me) = @_;
    my ($type)      = ref($self) || $self;

    # XXX-TODO: UNIX only.
    # XXX-TODO: we call "ypmatch" but should use full-path if could.
    # XXX-TODO: who validate $key value ?
    # emulate an array on memory
    my $key        = $me->{_name};
    my (@x)        = split(/:/, `ypmatch $key group.byname`);
    my (@elements) = split ',', $x[3];
    $me->{_array_reference} = \@elements;
}


=head1 SEE ALSO

L<IO::Adapter::Array>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::NIS first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
