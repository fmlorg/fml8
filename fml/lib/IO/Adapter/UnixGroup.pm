#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: UnixGroup.pm,v 1.13 2001/05/30 14:35:11 fukachan Exp $
#

package IO::Adapter::UnixGroup;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::Array;

@ISA = qw(IO::Adapter::Array);


=head1 NAME

IO::Adapter::UnixGroup - IO wrapper to read /etc/group

=head1 SYNOPSIS

    $map = 'unix.group:fml';

    use IO::Adapter;
    $obj = new IO::Adapter $map;
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

/etc/group has C<fml> entry like this:

  fml:*:1000:fukachan

=head1 DESCRIPTION

See L<IO::Adapter::Array> for more details.

C<CAUTION: this map is read only>.

=head1 METHOD

=head2 C<configure($obj)>

Configure object for array IO operation.

=cut


sub configure
{
    my ($self, $me) = @_;
    my ($type) = ref($self) || $self;

    # emulate an array on memory
    my (@x)        = getgrnam( $me->{_name} );
    my (@elements) = split ' ', $x[3];
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

IO::Adapter::UnixGroup appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
