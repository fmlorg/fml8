#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package File::RingBuffer;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use IO::File;

=head1 NAME

File::RingBuffer - IO operations to ring buffer which consists of files

=head1 SYNOPSIS

   ... lock e.g. by flock(2) ...

   use File::RingBuffer;
   $obj = new File::RingBuffer { 
       directory => '/some/where'
   };
   $fh = $obj->open;
   print $fh "some message";
   $fh->close;

   ... unlock ...

=head1 DESCRIPTION

To log messages but up to some limit, it may be useful to use a file
in cyclic way. It is chosen among a set of files as a buffer.

Consider several files under a directory C<ring/>
where the unit of the ring is 5 here.
C<ring/> may have 5 files in it. 

   0 1 2 3 4

To log a message is to write it to one of them.
At the first time the message is logged to the file C<1>, 
and next time to C<2> and so on.
If all 5 files are used, pick up and use (overwrite) the oldest one.
The oldest one is C<0>. 

We use a file in cyclic way as follows:

   0 -> 1 -> 2 -> 3 -> 4 -> 0 -> 1 -> ...

We expires the old data.
A file name is a number for simplicity.
The latest number is holded in C<ring/.seq> file (C<.seq> in that
direcotry by default) and truncated to 0 by the modulus C<5>.

=head1 METHODS

=cut


require Exporter;
@ISA = qw(IO::File);

BEGIN {}
END   {}


# Descriptions: constructor
#               forward new() request to superclass (IO::File)
#    Arguments: $class_name
# Side Effects: none
# Return Value: class object
#               XXX $self is blessed file handle.
sub new
{
    my ($self, $args) = @_;
    my $me = $self->SUPER::new();
    _take_file_name($me, $args);
    $me;
}


sub _take_file_name
{
    my ($self, $args) = @_;
    my $sequence_file_name = $args->{ sequence_file_name } || '.seq';
    my $modulus            = $args->{ modulus } || 128;

    use File::Spec;
    my $seq_file = 
      File::Spec->catfile($args->{ directory }, $sequence_file_name);
			  
    use File::Sequence;
    my $sfh = new File::Sequence {
	sequence_file => $seq_file,
	modulus       => $modulus,
    };
    my $id   = $sfh->increment_id;
    my $file = File::Spec->catfile($args->{ directory }, $id);
    ${*$self}{ _file } = $file;
}


# Descriptions: open() a file in the buffer
#    Arguments: $self
#               XXX $self is blessed file handle.
# Side Effects: create ${ *$self } hash to save status information
# Return Value: write file handle (for $file.new.$$)
sub open
{
    my ($self) = @_;

    # temporary file
    my $file = ${*$self}{ _file};

    # real open with $mode
    $self->autoflush;
    $self->SUPER::open($file, "w") ? $self : undef;
}


sub close
{
    my ($self) = @_;
    $self->SUPER::close();
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

File::RingBuffer appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
