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

require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub open
{
    my ($self, $args) = @_;

    my $file = $args->{ file };
    my $flag = $args->{ flag };
    my $fh;
    use FileHandle;
    $fh = new FileHandle $file, $flag;
    if (defined $fh) {
	$self->{_fh} = $fh;
	return $fh;
    }
    else {
	$self->_error_reason("Error: cannot open $file $flag");
	return undef;
    }
}


# debug tools
my $c = 0;
my $ec = 0;
sub line_count { my ($self) = @_; return "${ec}/${c}";}


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


sub getops
{
    my ($self) = @_;
    my $fh = $self->{_fh};
    defined $fh ? tell($fh) : undef;    
}


sub setops
{
    my ($self, $pos) = @_;
    my $fh = $self->{_fh};
    seek($fh, $pos, 0);
}


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


#####
##### This is just a dummy yet now.
#####


=head1 NAME

IO::MapAdapter::File.pm - what is this

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CLASSES

=head1 METHODS

=item C<new()>

... what is this ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

IO::MapAdapter::File.pm appeared in fml5.

=cut

1;
