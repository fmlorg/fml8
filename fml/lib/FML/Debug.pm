#-*- perl -*-
#
# Copyright (C) 2000-2001 Ken'ichi Fukamachi
#          All rights reserved. 
#
# $FML: Debug.pm,v 1.4 2001/04/03 09:45:40 fukachan Exp $
#

package FML::Debug;

=head1 NAME

FML::Debug -- debug utilities

=head1 SYNOPSIS

    use FML::Debug;
    FML::Debug->show_structure( $variable );

=head1 METHODS

=head2 C<show_structure($x)>

It shows the data structure for the given variable C<$x>.
It is just a wrapper for L<Data::Dumper>.

=cut


# Descriptions: constructor
#    Arguments: $self $args
# Side Effects: none
# Return Value: none
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    bless $me, $self,
}


# Descriptions: dump the target data structure
#    Arguments: $self $target
# Side Effects: none
# Return Value: none
sub show_structure
{
    my ($self, $target) = @_;
    use Data::Dumper;
    print Dumper( $target );
}


1;
