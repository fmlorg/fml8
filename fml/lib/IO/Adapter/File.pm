#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: File.pm,v 1.51 2004/01/24 09:03:56 fukachan Exp $
#

package IO::Adapter::File;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);


my $debug = 0;


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

=head2 new()

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


=head2 open($args)

$args HASH REFERENCE must have two parameters.
C<file> is the target file to open.
C<flag> is the mode of open().

=cut


# Descriptions: open map.
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


# Descriptions: open file in "read only" mode.
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


# Descriptions: open file in "read/write" mode.
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


=head2 touch()

create a file if not exists.

=cut


# Descriptions: touch (create a file if needed).
#    Arguments: OBJ($self)
# Side Effects: create a file
# Return Value: same as close()
sub touch
{
    my ($self) = @_;
    my $file   = $self->{_file};

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
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub line_count
{
    my ($self) = @_;
    return "${ec}/${c}";
}


=head2 getline()

return one line.
It is the same as usual getline() call for a file.

=cut


# Descriptions: get string for new line.
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


# Descriptions: return the next key.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub get_next_key
{
    my ($self) = @_;
    $self->_get_next_xxx('key');
}


# Descriptions: return (key, values, ... ) as ARRAY_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_key_values_as_array_ref
{
    my ($self) = @_;
    $self->_get_next_xxx('key,value_as_array_ref');
}


# Descriptions: get data and return key or value by $mode.
#    Arguments: OBJ($self) STR($mode)
# Side Effects: none
# Return Value: STR
sub _get_next_xxx
{
    my ($self, $mode) = @_;
    my ($buf) = '';
    my (@buf) = ();

    my $fh = $self->{_fh};
    if (defined $fh) {
      LINE:
	while ($buf = <$fh>) {
	    $c++; # for benchmark (debug)
	    next LINE if not defined $buf;
	    next LINE if $buf =~ /^\s*$/o;
	    next LINE if $buf =~ /^\#/o;
	    last LINE;
	}

	if (defined $buf) {
	    $buf =~ s/[\r\n]*$//o;
	    my ($key, $value) = split(/\s+/, $buf, 2);
	    if ($mode eq 'key') {
		$buf = $key;
	    }
	    elsif ($mode eq 'value_as_str') {
		$buf = $value;
	    }
	    elsif ($mode eq 'value_as_array_ref') {
		$value =~ s/^\s*//;
		$value =~ s/\s*$//;
		(@buf) = split(/\s+/, $value);
		$buf = \@buf;
	    }
	    elsif ($mode eq 'key,value_as_array_ref') {
		@buf = (); # reset;

		if (defined $key && $key) {
		    if (defined $value && $value) {
			$value =~ s/^\s*//o;
			$value =~ s/\s*$//o;
			(@buf) = split(/\s+/, $value);
		    }
		    unshift(@buf, $key);
		    $buf = \@buf;
		}
		else {
		    $buf = [];
		}
	    }
	    $ec++;
	}
	return $buf;
    }

    return undef;
}


=head2 getpos()

get the position in the opened file.

=head2 setpos(pos)

set the position in the opened file.

=cut


# Descriptions: return current postion in file descriptor.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub getpos
{
    my ($self) = @_;

    my $fh = $self->{_fh};
    defined $fh ? tell($fh) : undef;
}


# Descriptions: reset postion in file descriptor.
#    Arguments: OBJ($self) NUM($pos)
# Side Effects: none
# Return Value: NUM
sub setpos
{
    my ($self, $pos) = @_;

    my $fh = $self->{_fh};
    seek($fh, $pos, 0);
}


=head2 eof()

Eof Of File?

=head2 close()

close the opended file.

=cut


# Descriptions: check if EOF or not.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as eof()
sub eof
{
    my ($self) = @_;

    my $fh = $self->{_fh};
    $fh->eof if defined $fh;
}


# Descriptions: close map.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: same as close()
sub close
{
    my ($self) = @_;

    $self->{_fh}->close if defined $self->{_fh};
}


=head2 add($address, ... )

add (append) $address to this map.

=cut


# Descriptions: add $addr into map.
#    Arguments: OBJ($self) STR($addr) VARARGS($argv)
# Side Effects: update map
# Return Value: same as close()
sub add
{
    my ($self, $addr, $argv) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh && defined $wh) {
	my $buf;

      FILE_IO:
	while ($buf = <$fh>) {
	    print $wh $buf;
	}
	$fh->close;

	print STDERR "add: argv=$argv\tref=<", ref($argv), ">\n" if $debug;

	if (defined $argv) {
	    if (ref($argv) eq 'ARRAY') {
		print $wh $addr, "\t", join("\t", @$argv), "\n";
	    }
	    elsif (not ref($argv)) {
		print $wh $addr, "\t", $argv, "\n";
	    }
	    else {
		$self->error_set("Error: add: invalid args");
		$wh->close;
		return undef;
	    }
	}
	else {
	    print $wh $addr, "\n";
	}

	$wh->close;
    }
    else {
	$self->error_set("Error: cannot open file=$self->{ _file }");
	return undef;
    }
}


=head2 delete($key)

delete lines with key $key from this map.

=cut


# Descriptions: delete address(es) matching $reexp from map.
#    Arguments: OBJ($self) STR($key)
# Side Effects: update map
# Return Value: same as close()
sub delete
{
    my ($self, $key) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh) {
	my $key = quotemeta($key);
	my $buf;

      FILE_IO:
	while ($buf = <$fh>) {
	    next FILE_IO if $buf =~ /^$key\s+\S+|^$key\s*$/;
	    print $wh $buf;
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

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::File first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
