#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Array.pm,v 1.35 2004/01/24 09:03:55 fukachan Exp $
#

package IO::Adapter::Array;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

=head1 NAME

IO::Adapter::Array - base class for IO emulation for ARRAY_REF.

=head1 SYNOPSIS

    use IO::Adapter::Array;

    $map = [ 'rudo', 'kenken', 'hitomi' ];
    $obj = new IO::Adapter::Array $map;
    $obj->open;
    while ($x = $obj->get_next_key) { print $x;}
    $obj->close;

=head1 DESCRIPTION

emulate IO operation for the ARRAY_REF on memory.
One array is similar to a set of primary keys without optional values
such as a file:

    rudo
    kenken
    hitomi
      ...

=head1 METHODS

=item C<new()>

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2

=item C<open($args)>

open IO for the array ARRAY_REF. $args is a hash reference.
The option follows:

   $args = {
                  flag => $flag
      _array_reference => ARRAY_REFERENCE
   }

$flag is "r" only (read only) now.

=cut


# Descriptions: open() emulation.
#    Arguments: OBJ($self) HASH_REF($args)
#               $args = {
#                              flag => $flag
#                  _array_reference => ARRAY_REFERENCE
#               }
# Side Effects: malloc @elements array.
# Return Value: ARRAY_REF
sub open
{
    my ($self, $args) = @_;
    my $flag    = $args->{ flag } || 'r';
    my $r_array = $self->{ _array_reference } || [];

    if ($flag ne 'r') {
	$self->error_set("Error: type=$self->{_type} is read only.");
	return undef;
    }

    # malloc()
    my (@elements)         = @$r_array;
    $self->{_elements}     = $r_array;
    $self->{_num_elements} = $#elements;
    $self->{_counter}      = 0;
    return( @elements ? \@elements : [] );
}


=head2

=item C<getline()>

should not use this ?

=item C<get_next_key()>

return the next element of the array.

=cut


# Descriptions: forwarded to get_next_key().
#               XXX getline() == get_next_key() is valid in this case.
#               XXX since this map has only key and no value.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: increment the counter in the object
# Return Value: STR(the next element)
sub getline { get_next_key(@_);}


# Descriptions: return (key, values, ... ) as ARRAY_REF.
#               XXX no value in the case of this map.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_key_values_as_array_ref
{
    my ($self, $args) = @_;
    my $x = $self->get_next_key();
    return [ $x ];
}

# Descriptions: return the next element of the array.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: increment the counter in the object
# Return Value: STR(the next element)
sub get_next_key
{
    my ($self, $args) = @_;
    my $i  = $self->{_counter}++;
    my $ra = $self->{_elements};

    return( defined $$ra[ $i ] ? $$ra[ $i ] : undef );
}


=head2 getpos()

return the current position in the array.

=head2 setpos($pos)

set the current position to $pos -th element.

=cut

# Descriptions: return the current position in the array, that is,
#               which element in the array.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM(the current number of element)
sub getpos
{
    my ($self) = @_;
    return $self->{_counter};
}


# Descriptions: set the postion in the array.
#    Arguments: OBJ($self) NUM($pos)
#               $pos is the integer number.
# Side Effects: reset counter in the object
# Return Value: NUM(update position)
sub setpos
{
    my ($self, $pos)  = @_;
    $self->{_counter} = $pos;
}


=head2 eof()

whether the current position reaches the end of the array or not.
If it already reaches the end, return 1.

=head2 close()

end of IO operation. It is a dummy.

=cut


# Descriptions: echeck whether end of the array is not now.
#    Arguments: OJB($self)
# Side Effects: none
# Return Value: 1 or 0.
#               return 1 if the element reaches the end of the array.
sub eof
{
    my ($self) = @_;

    # XXX-TODO: > ? >= ? OK?
    $self->{_counter} > $self->{_num_elements} ? 1 : 0;
}


# Descriptions: close() is a fake.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub close
{
    my ($self) = @_;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::Array first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
