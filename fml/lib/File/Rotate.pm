#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Rotate.pm,v 1.9 2002/01/13 05:57:40 fukachan Exp $
#

package File::Rotate;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;

BEGIN {}
END   {}

=head1 NAME

File::Rotate - file rotatation utilities

=head1 SYNOPSIS

    $obj = new File::Rotate {
	max_size    => 10000,
	num_backlog => 4,
    };
    $obj->rotate( \@target_files );

=head1 DESCRIPTION

Utility functions for file rotate operations.
It turns over the given C<file> by some condition.
Typical condition is given as the number of files or how old they are.

C<rotation> renames and rearranges files like this:

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

In old age, shell script does this but
in modern unix,
some programs such as /usr/bin/newsyslog (MIT athena project) do.

=head1 METHODS

=head2 new($args)

ordinary constructor. $args accpets the following parameters.

   parameter       default value
   ------------------------
   max_size        300*1024
   num_backlog     4

=cut


# Descriptions: constructor
#               forward new() request to superclass (IO::File)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
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


=head2 C<is_time_to_rotate()>

C<stat()> the file correspoinding to the object and
determine whether the time to do comes or not.

=cut


# Descriptions: determine the time to rotate
#    Arguments: OBJ($self)
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


=head2 C<rotate()>

rename files to rotate it.

    rm file.4
    mv file.3 file.4
    mv file.2 file.3
    mv file.1 file.2
    mv file.0 file.1
    mv file   file.0

=cut


# Descriptions: rotate filenames
#    Arguments: OBJ($self)
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
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY(file, max_size, num_backlog)
sub _get_param
{
    my ($self) = @_;
    (${*$self}{_file}, ${*$self}{_max_size}, ${*$self}{_num_backlog});
}


=head2 C<error()>

return the error message if exists.

=cut


# Descriptions: return error message
#    Arguments: OBJ($self)
#               XXX $self is blessed file handle.
# Side Effects: none
# Return Value: STR(error message)
sub error
{
    my ($self) = @_;
    my $fh = $self;
    ${ *$fh }{ _error };
}


=head1 AUTHOR

Ken'ichi Fukamachi


=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

File::Rotate appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
