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

require Exporter;
@ISA = qw(IO::File);


sub BEGIN {}


sub new
{
    my ($class) = shift;
    my $self = $class->SUPER::new();
    $self->open(@_) if @_;
    $self;
}


sub open
{
    my ($self, $file, $mode) = @_;

    # get an instance 
    ref($self) or $self = $self->new;

    # default mode is "w"
    $mode ||= "w";

    # temporary file
    my $temp = $file.".new.".$$;
    ${*$self}{ _orig } = $file;
    ${*$self}{ _temp } = $temp;

    # real open with $mode
    $self->autoflush;
    $self->SUPER::open($temp, "w") ? $self : undef;
}


sub rw_open
{
    my ($self, $file, $mode) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    my $wh = $self->open($file, $mode);

    return ($rh, $wh);
}


sub close
{
    my ($self) = @_;
    my $fh = $self;
    my $orig = ${ *$fh }{ _orig };
    my $temp = ${ *$fh }{ _temp };

    if (rename($temp, $orig)) {
       ${ *$fh }{ _error } = "fail to rename($temp, $orig)";
    }
    else {
       undef;
    }
}


sub error
{
    my ($self) = @_;
    my $fh = $self;
    ${ *$fh }{ _error };
}


sub rollback
{
    my ($self) = @_;
    my $fh = $self;
    my $temp = ${ *$fh }{ _temp };
    if (-f $temp) { unlink $temp;}
}


sub DESTROY 
{ 
    my ($self) = @_;
    $self->rollback;
}


=head1 NAME

IO::Atomic.pm - atomic  operation


=head1 SYNOPSIS

    use IO::Atomic;
    my $wh = new IO::Atomic->open($file);
    print $wh "new/updated things ...";
    $wh->close;

So, in usual cases, you use in this way.

    use FileHandle;
    use IO::Atomic;

    # get read handle for $file
    my $rh = new FileHandle $file;

    # get  handle to update $file
    my $wh = new IO::Atomic->open($file);
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

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::__MODULE_NAME__.pm appeared in fml5.

=cut


1;
