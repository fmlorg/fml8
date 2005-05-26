#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: AtomicFile.pm,v 1.15 2004/07/23 15:59:13 fukachan Exp $
#

package IO::Adapter::AtomicFile;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $Counter);
use Carp;
use IO::File;
@ISA = qw(IO::File);

BEGIN {}
END   {}

=head1 NAME

IO::Adapter::AtomicFile - atomic IO operation.

=head1 SYNOPSIS

    use IO::Adapter::AtomicFile;
    my $wh = IO::Adapter::AtomicFile->open($file);
    if (defined $wh) {
	print $wh "new/updated things ...";
	$wh->close unless $wh->error;
    }

In C<close()> runs, the C<$file> is replaced with the new content.
Updating is defered until C<close()>.

In usual cases, you use this module in the following way.

    use FileHandle;
    use IO::Adapter::AtomicFile;

    # get read handle for $file
    my $rh = new FileHandle $file;

    # get handle to update $file
    my $wh = IO::Adapter::AtomicFile->open($file);
    if (defined $rh && defined $wh) {
	while (<$rh>) {
	    print $wh "new/updated things ...";
	}
	$wh->close;
	$rh->close;
    }

You can use this method to open $file for both read and write.

    use IO::Adapter::AtomicFile;
    my ($rh, $wh) = IO::Adapter::AtomicFile->rw_open($file);
    if (defined $rh && defined $wh) {
	while (<$rh>) {
	    print $wh "new/updated things ...";
	}
	$wh->close;
	$rh->close;
    }

To copy from $src to $dst,

    IO::Adapter::AtomicFile->copy($src, $dst) || croak("fail to copy");


=head1 DESCRIPTION

library to wrap atomic IO operations.
The C<atomic> feature is based on C<rename(2)> system call.

=head1 METHODS

=head2 new()

The ordinary constructor.
The request is forwarded to SUPER CLASS's new().

=cut

# Descriptions: ordinary constructor.
#               forward new() request to superclass (IO::File)
#               XXX returned object $self is blessed file handle.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, @argv) = shift;
    my $me = $self->SUPER::new(); # call IO::File::new().

    if (defined $me) {
	$me->open(@argv) if @argv;
	return $me;
    }
    elese {
	return undef;
    }
}


=head2 open(file[, mode])

open C<file> with C<mode>.
If C<mode> is not specified, open C<file> with writable mode by default.

Actually this method opens a new temporary file for write.
So to write this C<file> is to write the temporary file.
When close() method sucesses, the file is replaced with this temporary file.

=cut


# Descriptions: open( $file [, $mode] )
#               open not $file but file.new.$$
#               forward open() request to IO::File class
#    Arguments: OBJ($self) STR($file) [STR($mode)]
#               XXX $self is blessed file handle.
# Side Effects: create ${ *$self } hash to save status information
# Return Value: HANDLE(write file handle for $file.new.$$)
sub open
{
    my ($self, $file, $mode) = @_;

    # get an instance
    ref($self) or $self = $self->new;

    # default mode is "w"
    $mode ||= "w";

    # temporary file
    unless (defined $Counter) { $Counter = 0;}
    $Counter++;
    my $temp = sprintf("%s.%s.%s.%s", $file, "new", $$, $Counter);
    ${*$self}{ _orig_file } = $file;
    ${*$self}{ _temp_file } = $temp;

    # real open with $mode
    $self->autoflush;
    $self->SUPER::open($temp, "w") ? $self : undef;
}


=head2 rw_open(file[, mode])

return the file descriptor for both to read and write C<file>.
This is a wrapper for C<open()> method described above for conveninece.

=cut


# Descriptions: open $file with the mode $mode for both
#               reading and writing.
#    Arguments: OBJ($self) STR($file) [STR($mode)]
# Side Effects: none
# Return Value: ARRAY(HANDLE($rh for read), HANDLE($wh for write))
sub rw_open
{
    my ($self, $file, $mode) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    my $wh = $self->open($file, $mode);

    return ($rh, $wh);
}


=head2 close()

close the file.
After the file is closed, the file is renamed to the original file name.

=cut


# Descriptions: close "write" file handle
#               XXX "read" file handle is closed by SUPERCLASS.
#    Arguments: OBJ($self)
#               XXX $self is blessed file handle.
# Side Effects: rename the temporary file to the original file
#               save the error message in ${ *$fh }
# Return Value: NUM(1 if succeeded, 0 if failed)
sub close
{
    my ($self) = @_;
    my $fh   = $self;
    my $orig = ${ *$fh }{ _orig_file };
    my $temp = ${ *$fh }{ _temp_file };

    # XXX close the "write" file handle (write .. to $temp file)
    if (defined $fh) {
       $fh->SUPER::close();
    }

    # allow 0 bytes. e.g. in the case so that all content is removed.
    if (rename($temp, $orig)) {
       return 1;
    }
    else {
       ${ *$fh }{ _error } = "fail to rename($temp, $orig)";
       return 0;
    }
}


=head2 copy(src, dst)

copy from C<src> file to C<dst> file in atomic way by using
C<IO::Adapter::AtomicFile::rw_open>.

=cut


# Descriptions: copy file, which ensures atomic operation.
#    Arguments: OBJ($self) STR($src) STR($dst)
# Side Effects: $dst's file mode becomes the same as $src
# Return Value: NUM
sub copy
{
    my ($self, $src, $dst) = @_;
    my ($mode) = (stat($src))[2];

    my $rh = new FileHandle $src;
    my $wh = $self->open($dst);

    if (defined($rh) && defined($wh)) {
	my $buf = '';
	while (sysread($rh, $buf, 4096)) { print $wh $buf;}
	$wh->close;
	$rh->close;

	# XXX-TODO: chmod too late
	chmod $mode, $dst;
    }
    else {
	return undef;
    }
}


=head2 error()

return the error.

=head2 rollback()

stop the operation and remove the temporary file to back to the first
state.

=cut


# Descriptions: return error message.
#    Arguments: OJB($self)
#               XXX $self is blessed file handle.
# Side Effects: none
# Return Value: STR(error message string)
sub error
{
    my ($self) = @_;
    my $fh = $self;
    ${ *$fh }{ _error };
}


# Descriptions: reset the previous work.
#    Arguments: OBJ($self)
#               XXX $self is blessed file handle.
# Side Effects: clean up the previous work ;-)
#               remove temporary files we created
# Return Value: NUM
sub rollback
{
    my ($self) = @_;
    my $fh   = $self;
    my $temp = ${ *$fh }{ _temp_file };
    if (-f $temp) { unlink $temp;}
}


# Descriptions: destructor.
#               forward the request to rollback() in this class.
#    Arguments: OBJ($self)
#               XXX $self is blessed file handle.
# Side Effects: none
# Return Value: the same as rollback()
sub DESTROY
{
    my ($self) = @_;
    $self->rollback;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

IO::Adapter::AtomicFile first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
