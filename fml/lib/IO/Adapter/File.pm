#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: File.pm,v 1.36 2002/07/25 11:34:02 fukachan Exp $
#

package IO::Adapter::File;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);

=head1 NAME

IO::Adapter::File - IO functions for a file

=head1 SYNOPSIS

    $map = 'file:/some/where/file';

To read list

    use IO::Adapter;
    $obj = new IO::Adapter $map;
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

To add the address

    $obj = new IO::Adapter $map;
    $obj->add( $address );

To delete it

    $regexp = "^$address";
    $obj->delete( $regexp );

=head1 DESCRIPTION

This module provides real IO functions for a file used in
C<IO::Adapter>.
The map is the fully path-ed file name or a file name with 'file:/'
prefix.

=head1 METHODS

=head2 C<new()>

standard constructor.

=cut


# Descriptions: standard constructor.
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


=head2 C<open($args)>

$args HASH REFERENCE must have two parameters.
C<file> is the target file to open.
C<flag> is the mode of open().

=cut


# Descriptions: open map
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: file opened
# Return Value: HANDLE
sub open
{
    my ($self, $args) = @_;
    my $file = $args->{ file };
    my $flag = $args->{ flag };

    if ($flag eq 'r') {
	$self->_read_open($args); # read only open()
    }
    else {
	$self->_rw_open($args); # read/write open in atomic way
    }
}


# Descriptions: open file in "read only" mode
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: file is opened for read
# Return Value: HANDLE
sub _read_open
{
    my ($self, $args) = @_;
    my $file = $args->{ file };
    my $flag = $args->{ flag };

    use FileHandle;
    my $fh = new FileHandle $file, $flag;
    if (defined $fh) {
	$self->{_fh} = $fh;
	return $fh;
    }
    else {
	$self->error_set("Error: cannot open file=$file flag=$flag");
	return undef;
    }
}


# Descriptions: open file in "read/write" mode
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: file is opened for read
# Return Value: HANDLE
sub _rw_open
{
    my ($self, $args) = @_;
    my $file = $args->{ file };
    my $flag = $args->{ flag };

    use IO::Adapter::AtomicFile;
    my ($rh, $wh)  = IO::Adapter::AtomicFile->rw_open($file);
    $self->{ _fh } = $rh;
    $self->{ _wh } = $wh;
    $rh;
}


=head2 C<touch()>

create a file if not exists.

=cut


# Descriptions: touch (create a file if needed)
#    Arguments: OBJ($self)
# Side Effects: create a file
# Return Value: same as close()
sub touch
{
    my ($self) = @_;
    my $file = $self->{_file};

    use IO::File;
    my $fh = new IO::File;
    if (defined $fh) {
	$fh->open($file, "a");
	$fh->close;
    }
}


# debug tools
my $c  = 0;
my $ec = 0;


# Descriptions: line couter (for debug).
#               XXX remove this in the future
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub line_count
{
    my ($self) = @_;
    return "${ec}/${c}";
}


=head2 C<getline()>

return one line.
It is the same as usual getline() call for a file.

=head2 C<get_next_value()>

return one line suitable with C<fml> IO design.
This is used in C<fml5>.

=cut


# Descriptions: get string for new line
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub getline
{
    my ($self) = @_;
    my $fh = $self->{_fh};

    if (defined $fh) {
	$fh->getline;
    }
    else {
	return undef;
    }
}


# Descriptions: return the next key
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_next_key
{
    my ($self) = @_;
    $self->_get_next_xxx('key');
}


# Descriptions: return value(s) for the next key
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_next_value
{
    my ($self) = @_;
    $self->_get_next_xxx('value');
}


# Descriptions: get data and return key or value by $mode.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: none
# Return Value: STR
sub _get_next_xxx
{
    my ($self, $mode) = @_;

    my ($buf) = '';
    my $fh = $self->{_fh};

    if (defined $fh) {
      INPUT:
	while ($buf = <$fh>) {
	    $c++; # for benchmark (debug)
	    next INPUT if not defined $buf;
	    next INPUT if $buf =~ /^\s*$/o;
	    next INPUT if $buf =~ /^\#/o;
	    last INPUT;
	}

	if (defined $buf) {
	    $buf =~ s/[\r\n]*$//o;
	    my ($key, $value) = split(/\s+/, $buf, 2);
	    if ($mode eq 'key') {
		$buf = $key;
	    }
	    elsif ($mode eq 'value') {
		$buf = $value;
	    }
	    $ec++;
	}
	return $buf;
    }
    return undef;
}


=head2 C<getpos()>

get the position in the opened file.

=head2 C<setpos(pos)>

set the position in the opened file.

=cut


# Descriptions: return current postion in file descriptor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub getpos
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    defined $fh ? tell($fh) : undef;
}


# Descriptions: reset postion in file descriptor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub setpos
{
    my ($self, $pos) = @_;
    my $fh = $self->{_fh};
    seek($fh, $pos, 0);
}


=head2 C<eof()>

Eof Of File?

=head2 C<close()>

close the opended file.

=cut


# Descriptions: EOF or not
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as eof()
sub eof
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    $fh->eof if defined $fh;
}


# Descriptions: close map
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as close()
sub close
{
    my ($self) = @_;
    $self->{_fh}->close if defined $self->{_fh};
}


=head2 C<add($address)>

add (append) $address to this map.

=cut


# Descriptions: add $addr into map
#    Arguments: OBJ($self) STR($addr)
# Side Effects: update map
# Return Value: same as close()
sub add
{
    my ($self, $addr) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh && defined $wh) {
      FILE_IO:
	while (<$fh>) {
	    print $wh $_;
	}
	$fh->close;
    }
    else {
	$self->error_set("Error: cannot open file=$self->{ _file }");
	return undef;
    }

    print $wh $addr, "\n";
    $wh->close;
}


=head2 C<delete($regexp)>

delete lines which matches $regexp from this map.

=cut


# Descriptions: delete address(es) matching $reexp from map
#    Arguments: OBJ($self) STR($regexp)
# Side Effects: update map
# Return Value: same as close()
sub delete
{
    my ($self, $regexp) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh) {
      FILE_IO:
	while (<$fh>) {
	    next FILE_IO if /$regexp/;
	    print $wh $_;
	}
	$fh->close;
	$wh->close;
    }
    else {
	$self->error_set("Error: cannot open file=$self->{ _file }");
	return undef;
    }
}


=head1 SEE ALSO

L<IO::Adapter>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::File appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
