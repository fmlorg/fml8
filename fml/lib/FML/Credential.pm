#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Credential;

use strict;
use vars qw(%Credential @ISA @EXPORT @EXPORT_OK);
use Carp;

require Exporter;
@ISA       = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%Credential;
    return bless $me, $type;
}


sub is_member
{
    1;
}


sub get
{
    my ($self, $key) = @_;
    $self->{ $key };	
}


sub set
{
    my ($self, $key, $value) = @_;
    $self->{ $key } = $value;
}


=head1 NAME

FML::Credential.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Credential.pm appeared in fml5.

=cut


1;
