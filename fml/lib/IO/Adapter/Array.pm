#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML: Array.pm,v 1.17 2001/04/03 09:45:45 fukachan Exp $
#

package IO::Adapter::Array;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

=head1 NAME

IO::Adapter::Array - emulation of IO for the ARRAY

=head1 SYNOPSIS

    use IO::Adapter::Array;

    $map = [ 1, 2, 3 ];
    $obj = new IO::Adapter::Array $map;
    $obj->open;
    while ($x = $obj->get_next_value) { print $x;}
    $obj->close;

=head1 DESCRIPTION

emulate IO operation for the ARRAY.

=head1 METHODS

=item C<new()>

constructor. It is a dummy in fact now.

=cut

# Descriptions: constructor
#    Arguments: $self
# Side Effects: none
# Return Value: object
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2

=item C<open($args)>

open IO for the array. $args is a hash reference. 
The option follows:

   $args = {
                  flag => $flag
      _array_reference => ARRAY_REFERENCE
   }

$flag is "r" only (read only) now.

=cut

# Descriptions: open() emulation
#    Arguments: $self $args
#               $args = {
#                              flag => $flag
#                  _array_reference => ARRAY_REFERENCE
#               }
# Side Effects: malloc @elements array
# Return Value: ARRAY REFERENCE
sub open
{
    my ($self, $args) = @_;
    my $flag    = $args->{ flag } || 'r';
    my $r_array = $self->{ _array_reference};

    if ($flag ne 'r') {
	$self->error_set("Error: type=$self->{_type} is read only.");
	return undef;
    }

    # malloc()
    my @elements = @$r_array;
    $self->{_elements}     = $r_array;
    $self->{_num_elements} = $#elements;
    $self->{_counter}      = 0;
    return( @elements ? \@elements : undef );
}


=head2

=item C<getline()>

the same as get_next_value().

=item C<get_next_value()>

return the next element of the array

=cut

# Descriptions: forwarded to get_next_value()
sub getline { get_next_value(@_);} 


# Descriptions: return the next element of the array
#    Arguments: $self $args
# Side Effects: increment the counter in the object
# Return Value: the next element
sub get_next_value
{
    my ($self, $args) = @_;
    my $i  = $self->{_counter}++;
    my $ra = $self->{_elements};
    defined $$ra[ $i ] ? $$ra[ $i ] : undef;
}


# Descriptions: return the current position in the array, that is,
#               which element in the array
#    Arguments: $self
# Side Effects: none
# Return Value: the current number of element
sub getpos
{
    my ($self) = @_;
    return $self->{_counter};
}


# Descriptions: set the postion in the array
#    Arguments: $self $pos
#               $pos is the integer number.
# Side Effects: reset counter in the object
# Return Value: update position
sub setpos
{
    my ($self, $pos) = @_;
    $self->{_counter} = $pos;
}


# Descriptions: whether end of the array is not now
#    Arguments: $self
# Side Effects: none
# Return Value: 1 or 0. 
#               return 1 if the element reaches the end of the array.
sub eof
{
    my ($self) = @_;
    $self->{_counter} > $self->{_num_elements} ? 1 : 0;
}


# Descriptions: close() is a fake.
#    Arguments: $self
# Side Effects: none
# Return Value: none
sub close
{
    my ($self) = @_;
}


=head2

=item C<getpos()>

return the current position in the array

=item C<setpos($pos)>

set the current position to $pos -th element.

=item C<eof()>

whether the current position reaches the end of the array or not.
If it already reaches the end, return 1.

=item C<close()>

end of IO operation. It is a dummy.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::Array appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
