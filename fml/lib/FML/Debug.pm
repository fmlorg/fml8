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

=head1 METHODS

=item show_structure()

It shows the data structure for the given variable.
It is just an wrapper for L<Data::Dumper>.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    bless $me, $self,
}


# Descriptions: dump the target data structure
#    Arguments: $self target
# Side Effects: none
# Return Value: none
sub show_structure
{
    my ($self, $r_target) = @_;
    use Data::Dumper;
    print Dumper( $r_target );
}


1;
