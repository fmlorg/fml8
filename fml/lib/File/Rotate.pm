#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package File::Rotate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

BEGIN {}
END   {}

=head1 NAME

FILE::Rotate - IO with rotate operations

=head1 SYNOPSIS

    $obj = new FILE::Rotate {
	max_size    => 10000,
	num_backlog => 4,
    };
    $obj->rotate( \@target_files );

=head1 DESCRIPTION

library to wrap Rotate IO operations. 
It automatically rotates $file in close() operation. 
C<rotation> rearranges files like this:

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

=cut

# Descriptions: constructor
#               forward new() request to superclass (IO::File)
#    Arguments: $class_name $HASH_REFERENCE
# Side Effects: none
# Return Value: class object
#               XXX $self is blessed file handle.
sub new
{
    my ($self, $args) = shift;
    my ($type) = ref($self) || $self;
    my $me     = {};

    if ( ref($args->{ file_list }) eq 'ARRAY' ) {
	$me->{ _file_list   } = $args->{ file_list };
    }
    $me->{ _max_size    } = $args->{ max_size }    || 300*1024;
    $me->{ _num_backlog } = $args->{ num_backlog } || 4;

    return bless $me, $type;
}


# Descriptions: determine the time to rotate comes
#    Arguments: $self
# Side Effects: none
# Return Value: 1 (time comes!) or 0
sub is_time_to_rotate
{
    my ($self) = @_;
    my ($file, $size, $max) = $self->_get_param();

    use File::stat;
    my $st = stat($file);

    return 1 if $st->size > $size;
    return 0;
}



# Descriptions: rotate filenames
#    Arguments: $self
# Side Effects: filename rotations
#               unlink the oldest file
# Return Value: none
sub rotate
{
    my ($self) = @_;
    my ($file, $size, $max) = $self->_get_param();

    # remove oldest file
    my $maxfile = $file.".".$max;
    if (-f $maxfile) { unlink $maxfile;}

    # mv var/log/file.3 -> var/log/file.4 ...;
    do { 
	my $old = "$file.".($max - 1 > 0 ? $max - 1 : 0);
	my $new = "$file.".($max);
	print STDERR "rename($old, $new)" if -f $old;
	-f $old && rename($old, $new);
	$max--;
    } while ($max > 0);
}


# Descriptions: extract parameters in $self
#    Arguments: $self
# Side Effects: none
# Return Value: a set of (file, max_size, num_backlog)
sub _get_param
{
    my ($self) = @_;
    (${*$self}{_file}, ${*$self}{_max_size}, ${*$self}{_num_backlog});
}


# Descriptions: return error message
#    Arguments: $self
#               XXX $self is blessed file handle.
# Side Effects: none
# Return Value: error message string
sub error
{
    my ($self) = @_;
    my $fh = $self;
    ${ *$fh }{ _error };
}


=head1 AUTHOR

Ken'ichi Fukamachi


=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::Rotate appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
