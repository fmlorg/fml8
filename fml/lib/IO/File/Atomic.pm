#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::File::Atomic;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use IO::File;

require Exporter;
@ISA = qw(IO::File);

BEGIN {}
END   {}

=head1 NAME

IO::Atomic - atomic  operation

=head1 SYNOPSIS

    use IO::Atomic;
    my $wh = IO::Atomic->open($file);
    print $wh "new/updated things ...";
    $wh->close;

So, in usual cases, you use in this way.

    use FileHandle;
    use IO::Atomic;

    # get read handle for $file
    my $rh = new FileHandle $file;

    # get  handle to update $file
    my $wh = IO::Atomic->open($file);
    while (<$rh>) {
        print $wh "new/updated things ...";
    } 
    $wh->close;
    $rh->close;

You can use this method to open $file for both read and write.

    use IO::Atomic;
    my ($rh, $wh) = IO::Atomic->rw_open($file);
    while (<$rh>) {
        print $wh "new/updated things ...";    
    }
    $wh->close;
    $rh->close;

=head1 DESCRIPTION

=cut

# Descriptions: constructor
#               forward new() request to superclass (IO::File)
#    Arguments: $class_name
# Side Effects: none
# Return Value: class object
#               XXX $self is blessed file handle.
sub new
{
    my ($self) = shift;
    my $me = $self->SUPER::new();
    $me->open(@_) if @_;
    $me;
}


# Descriptions: open( $file [, $mode] )
#               open not $file but file.new.$$
#               forward open() request to IO::File class
#    Arguments: $self $file [$mode]
#               XXX $self is blessed file handle.
# Side Effects: create ${ *$self } hash to save status information
# Return Value: write file handle (for $file.new.$$)
sub open
{
    my ($self, $file, $mode) = @_;

    # get an instance 
    ref($self) or $self = $self->new;

    # default mode is "w"
    $mode ||= "w";

    # temporary file
    my $temp = $file.".new.".$$;
    ${*$self}{ _orig_file } = $file;
    ${*$self}{ _temp_file } = $temp;

    # real open with $mode
    $self->autoflush;
    $self->SUPER::open($temp, "w") ? $self : undef;
}


# Descriptions: open $file with the mode $mode for both
#               reading and writing.
#    Arguments: $class_name $file [$mode]
# Side Effects: none
# Return Value: LIST of file handle (read, write)
sub rw_open
{
    my ($self, $file, $mode) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    my $wh = $self->open($file, $mode);

    return ($rh, $wh);
}


# Descriptions: close "write" file handle
#               XXX "read" file handle is closed by SUPERCLASS.
#    Arguments: $self
#               XXX $self is blessed file handle.
# Side Effects: rename the temporary file to the original file
#               save the error message in ${ *$fh }
# Return Value: 1 if succeeded, 0 if failed
sub close
{
    my ($self) = @_;
    my $fh   = $self;
    my $orig = ${ *$fh }{ _orig_file };
    my $temp = ${ *$fh }{ _temp_file };

    # XXX close the "write" file handle (write .. to $temp file)
    close($fh);

    if (rename($temp, $orig)) {
       return 1;
    }
    else {
       ${ *$fh }{ _error } = "fail to rename($temp, $orig)";
       return 0;
    }
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


# Descriptions: reset the previous work
#    Arguments: $self
#               XXX $self is blessed file handle.
# Side Effects: clean up the previous work ;-)
#               remove temporary files we created
# Return Value: none
sub rollback
{
    my ($self) = @_;
    my $fh = $self;
    my $temp = ${ *$fh }{ _temp_file };
    if (-f $temp) { unlink $temp;}
}


# Descriptions: destructor
#               forward the request to rollback() in this class 
#    Arguments: $self
#               XXX $self is blessed file handle.
# Side Effects: none
# Return Value: the same as rollback()
sub DESTROY 
{ 
    my ($self) = @_;
    $self->rollback;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::File::Atomic.pm appeared in fml5.

=cut

1;
