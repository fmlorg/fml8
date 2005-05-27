#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: File.pm,v 1.60 2004/08/14 05:02:00 fukachan Exp $
#

package IO::Adapter::File;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD
	    $Counter %LockedFileHandle %FileIsLocked);
use Carp;
use IO::Adapter::ErrorStatus qw(error_set error error_clear);


my $debug = 0;


=head1 NAME

IO::Adapter::File - IO functions for a file.

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
	$self->error_set("cannot open file=$file flag=$flag");
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

    return $rh;
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

    use FileHandle;
    my $fh = new FileHandle;
    if (defined $fh) {
        $fh->open($file, "a");
	$fh->close();
    }
}


#
# debug tools
#
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
		$buf = $key || '';
	    }
	    elsif ($mode eq 'value_as_str') {
		$buf = $value || '';
	    }
	    elsif ($mode eq 'value_as_array_ref') {
		$value =~ s/^\s*//;
		$value =~ s/\s*$//;
		(@buf) = split(/\s+/, $value);
		$buf = \@buf || [];
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
		    $buf = \@buf || [];
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

    # XXX-TODO: open only if not opened ?
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
		$self->error_set("add: invalid args");
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
	$self->error_set("cannot open file=$self->{ _file }");
	return undef;
    }
}


=head2 delete($key)

delete lines with key $key from this map.

=cut


# Descriptions: delete address(es) matching $regexp from map.
#    Arguments: OBJ($self) STR($key)
# Side Effects: update map
# Return Value: same as close()
sub delete
{
    my ($self, $key) = @_;
    my $found = 0;

    # XXX-TODO: open only if not opened ?
    $self->open("w");

    my $fh = $self->{ _fh };
    my $wh = $self->{ _wh };

    if (defined $fh && defined $wh) {
	my $buf;

	$wh->autoflush(1);

      FILE_IO:
	while ($buf = <$fh>) {
	    if ($buf =~ /^$key\s+\S+|^$key\s*$/) {
		$found++;
		next FILE_IO;
	    }
	    print $wh $buf;
	}
	$wh->close;
	$fh->close;

	unless ($found) {
	    $self->error_set("not match");
	}
    }
    else {
	$self->error_set("cannot open file=$self->{ _file }");
	return undef;
    }
}


=head1 LOCK

=head2 lock($args)

=head2 unlock($args)

=cut


# Descriptions: flock file (create a file if needed).
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a file if needed.
# Return Value: none
sub lock
{
    my ($self, $args) = @_;
    my $file = $args->{ file };

    $self->_simple_flock($file);
}


# Descriptions: un-flock file.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub unlock
{
    my ($self, $args) = @_;
    my $file = $args->{ file };

    $self->_simple_funlock($file);
}


# Descriptions: try flock(2) for $file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: flock for $file
# Return Value: 1 or 0
sub _simple_flock
{
    my ($self, $file) = @_;

    use FileHandle;
    my $fh = new FileHandle ">> $file";

    if (defined $fh) {
	print STDERR "\tdebug[$$]: try lock $file\n" if $debug;

	$LockedFileHandle{ $file } = $fh;

	my $r = 0; # return value
	eval q{
	    use Fcntl qw(:DEFAULT :flock);
	    $r = flock($fh, &LOCK_EX);
	};
	$self->error_set($@) if $@;

	if ($r) {
	    print STDERR "\tdebug[$$]: $file LOCKED\n" if $debug;
	    $FileIsLocked{ $file } = 1;
	    return 1;
	}
    }
    else {
	$self->error_set("cannot open $file");
    }

    return 0;
}


# Descriptions: try unlock by flock(2) for $file.
#    Arguments: OBJ($self) STR($file)
# Side Effects: flock for $file
# Return Value: NUM( 1 or 0 )
sub _simple_funlock
{
    my ($self, $file) = @_;

    print STDERR "\tdebug[$$]: call unlock $file\n" if $debug;

    return 0 unless $FileIsLocked{ $file };
    return 0 unless $LockedFileHandle{ $file };

    my $fh = $LockedFileHandle{ $file };

    print STDERR "\tdebug[$$]: try unlock $file\n" if $debug;

    my $r = 0; # return value
    eval q{
	use Fcntl qw(:DEFAULT :flock);
	$r = flock($fh, &LOCK_UN);
    };
    $self->error_set($@) if $@;

    if ($r) {
	print STDERR "\tdebug[$$]: $file UNLOCKED\n" if $debug;
	delete $FileIsLocked{ $file };
	delete $LockedFileHandle{ $file };
	return 1;
    }

    return 0;
}


=head1 SEQUENCE FILE OPERATION

=head2 sequence_increment($args)

For example, to get a new (incremented) sequence number of mailing
list article:

    sub get_sequence_id
    {
	... lock ...;

	my $obj = new IO::Adapter $map;
	my $id  = $obj->sequence_increment();
	unless ($obj->error()) {
	    return $id;
	}
	else {
	    print $obj->error(), "\n";
	}

	... unlock ...;
    }

=head2 sequence_replace($args)

For example, to set sequence number to the specified value $new_id:

    sub set_sequence_id
    {
	my ($self, $new_id) = @_;

	... lock ...;

	my $obj = new IO::Adapter $map;
	my $id  = $obj->sequence_replace($new_id);
	unless ($obj->error()) {
	    return "ok";
	}
	else {
	    print $obj->error(), "\n";
	    return "fail";
	}

	... unlock ...;
    }

=cut


# Descriptions: increment value in the specified file.
#               return new sequence number.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a file if needed.
# Return Value: NUM
sub sequence_increment
{
    my ($self, $args) = @_;
    my $backup = sprintf("%s.%d.%d.%d.bak", 
			 $args->{ file }, time, $$, $Counter++);
    my $file   = $args->{ file };
    my $id     = 0;

    unless (-f $file) { $self->touch();}

    if (-f $file) {
	unless (link($file, $backup)) {
	    $self->error_set("failed to link.");
	    return 0;
	}
    }

    use IO::Adapter::AtomicFile;
    my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($file);

    if ($rh->error || $wh->error) {
	$self->error_set("failed to open temporary files.");
	unlink($backup) if -f $backup;
	return 0;
    }

    # read the current sequence number
    if (defined $rh) {
	$id = $self->_read_one_word($rh);
	$rh->close;
    }
    else {
	$self->error_set("cannot open the sequence file");
	unlink($backup) if -f $backup;
	return 0;
    }

    # increment
    if ($id =~ /^\d+$/ || $id eq '') {
	$id++;
    }
    else {
	$self->error_set("file contains not a number");
	unlink($backup) if -f $backup;
	return 0;
    }

    # save $id
    if (defined $wh) {
	$wh->autoflush(1);
	$wh->clearerr();
	print $wh $id, "\n";
	if ($wh->error()) {
	    $self->error_set("write error");
	    $wh->rollback();
	    unlink($backup) if -f $backup;
	    return 0;
	}
	else {
	    $wh->close;
	}
    }
    else {
	$self->error_set("cannot save id");
    }

    # verify if the value is writtern.
    {
	use IO::Adapter::AtomicFile;
	my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($file);
	if (defined $rh) {
	    my $new_id = $self->_read_one_word($rh);
	    unless ($new_id == $id) {
		$self->error_set("failed to save id");

		# rollback
		rename($backup, $file);

		return 0;
	    }
	    $rh->close();
	}
    }

    unlink($backup) if -f $backup;
    return $id;
}


# Descriptions: replace value with the specified one.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: create a file if needed.
# Return Value: none
sub sequence_replace
{
    my ($self, $args) = @_;
    my $file   = $args->{ file };
    my $new_id = $args->{ value };

    unless (-f $file) { $self->touch();}

    use IO::Adapter::AtomicFile;
    my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($file);
    if (defined $rh) { $rh->close();}

    # save $id
    if (defined $wh) {
	$wh->clearerr();
	print $wh $new_id, "\n";
	if ($wh->error()) {
	    $self->error_set("write error");
	    $wh->rollback();
	    return 0;
	}
	else {
	    $wh->close;
	}
    }
    else {
	$self->error_set("cannot save id");
	return 0;
    }

    # verify if the value is writtern.
    {
	use IO::Adapter::AtomicFile;
	my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($file);
	if (defined $rh) {
	    my $id = $self->_read_one_word($rh);
	    unless ($new_id == $id) {
		# XXX-TODO: need to rollback ?
		$self->error_set("fail to save id");
	    }
	    $rh->close();
	}
    }
}


# Descriptions: read the first line from $rh handle and return it.
#    Arguments: OBJ($self) HANDLE($rh)
# Side Effects: none
# Return Value: NUM
sub _read_one_word
{
    my ($self, $rh) = @_;
    my $id = 0;

    if (defined $rh) {
	$id = $rh->getline() || 0;
	$id =~ s/^[\s\r\n]*//;
	$id =~ s/[\s\r\n]*$//;
    }

    return $id;
}


=head1 SEE ALSO

L<IO::Adapter>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::File first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
