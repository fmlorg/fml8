#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML$
#

package FML::Debug;

=head1 NAME

FML::Debug -- debug utilities

=head1 SYNOPSIS

    use FML::Debug;
    FML::Debug->show_structure( $variable );

=head1 METHOD

=item show_structure()

It shows the data structure for the given variable.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    bless $me, $self,
}


sub show_structure
{
    my ($class, $ref) = @_;
    use Data::Dumper;
    print Dumper( $ref );
}


1;
