#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::Adapter::File;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

IO::Adapter::File - IO functions for a file

=head1 SYNOPSIS

    $map = 'file:/some/where/file';

To read list

    use IO::MapAdapter;
    $obj = new IO::MapAdapter $map;
    $obj->open || croak("cannot open $map");
    while ($x = $obj->getline) { ... }
    $obj->close;

To add the address

    $obj = new IO::MapAdapter $map;
    $obj->add( $address );

To delete it

    $regexp = "^$address";
    $obj->delete( $regexp );

=head1 DESCRIPTION

This module provides real IO functions for a file used in
IO::MapAdapter. 
The map is the fully path-ed file name or a file name with 'file:/'
prefix. 

=head1 METHODS

=head2 C<new()>

standard constructor.

=cut


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
#    Arguments: $self $args
# Side Effects: file is opened for read
# Return Value: file descriptor
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
	$self->_error_reason("Error: cannot open file=$file flag=$flag");
	return undef;
    }
}


sub _rw_open
{
    my ($self, $args) = @_;
    my $file = $args->{ file };
    my $flag = $args->{ flag };

    require IO::File::Atomic;
    my ($rh, $wh)  = IO::File::Atomic->rw_open($file);
    $self->{ _fh } = $rh;
    $self->{ _wh } = $wh;
    $rh;
}


# debug tools
my $c = 0;
my $ec = 0;
sub line_count { my ($self) = @_; return "${ec}/${c}";}


=head2 C<getline()>

return one line.
It is the same as usual getline() call for a file.

=head2 C<get_next_value()>

return one line suitable with C<fml> IO design.
This is used in C<fml5>.

=cut


sub getline
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    $fh->getline;
}


sub get_next_value
{
    my ($self) = @_;

    my ($buf) = '';
    my $fh = $self->{_fh};

    if (defined $fh) {
      INPUT:
	while ($buf = <$fh>) {
	    $c++; # for benchmark (debug)
	    next INPUT if not defined $buf;
	    next INPUT if $buf =~ /^\s*$/o;
	    next INPUT if $buf =~ /^\#/o;
	    next INPUT if $buf =~ /\sm=/o;
	    next INPUT if $buf =~ /\sr=/o;
	    next INPUT if $buf =~ /\ss=/o;
	    last INPUT;
	}

	if (defined $buf) {
	    my @buf = split(/\s+/, $buf);
	    $buf    = $buf[0];
	    $buf    =~ s/[\r\n]*$//o;
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


sub getpos
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    defined $fh ? tell($fh) : undef;    
}


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


sub eof
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    $fh->eof if defined $fh;
}


sub close
{
    my ($self) = @_;
    $self->{_fh}->close if defined $self->{_fh};
}


=head2 C<add($address)>

add (append) $address to this map.

=cut

sub add
{
    my ($self, $addr) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh) {
      FILE_IO:
	while (<$fh>) {
	    print $wh $_;
	}
	close($fh);
    }
    else {
	$self->_error_reason("Error: cannot open file=$self->{ _file }");
	return undef;
    }

    print $wh $addr, "\n";
    $wh->close;
}


=head2 C<delete($regexp)>

delete lines which matches $regexp from this map.

=cut

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
	close($fh);
	$wh->close;
    }
    else {
	$self->_error_reason("Error: cannot open file=$self->{ _file }");
	return undef;
    }
}


=head2 C<replace($regexp, $value)>

replace lines which matches $regexp with $value.

=cut

sub replace
{
    my ($self, $regexp, $value) = @_;

    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh) {
      FILE_IO:
	while (<$fh>) {
	    if (/$regexp/) {
		print $wh $value, "\n";
	    }
	    else {
		print $wh $_;
	    }
	}
	close($fh);
	$wh->close;
    }
    else {
	$self->_error_reason("Error: cannot open file=$self->{ _file }");
	return undef;
    }
}


=head1 SEE ALSO

L<IO::MapAdapter>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::Adapter::File appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
