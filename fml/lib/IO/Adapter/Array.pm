#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package IO::Adapter::Array;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;


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
    my $flag    = $args->{ flag } || 'r';
    my $r_array = $self->{ _array_reference};

    # malloc()
    my @members = @$r_array;
    $self->{_members}     = $r_array;
    $self->{_num_members} = $#members;
    $self->{_counter}     = 0;
    return defined @members ? \@members : undef;
}


# raw line reading
sub getline { get_next_value(@_);} 


sub get_next_value
{
    my ($self, $args) = @_;
    my $i  = $self->{_counter}++;
    my $ra = $self->{_members};
    defined $$ra[ $i ] ? $$ra[ $i ] : undef;
}


sub getpos
{
    my ($self) = @_;
    return $self->{_counter};
}


sub setpos
{
    my ($self, $pos) = @_;
    $self->{_counter} = $pos;
}


sub eof
{
    my ($self) = @_;
    $self->{_counter} > $self->{_num_members} ? 1 : 0;
}


sub close
{
    my ($self) = @_;
}


=head1 NAME

IO::Adapter::Array.pm - what is this

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

IO::Adapter::Array.pm appeared in fml5.

=cut

1;
