#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Body;

=head1 NAME

FML::Body - mail body manipulators

=head1 SYNOPSIS

... not yet documentd ...

=head1 DESCRIPTION

... not yet documentd ...

... not yet documentd ...

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Body.pm appeared in fml5.

=cut

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;
@ISA       = qw(Exporter);


sub new
{
    my ($self, $r_body) = @_;
    my ($type) = ref($self) || $self;
    return bless $r_body, $type;
}


sub size
{
    my ($self) = @_;
    length($self);
}


sub is_empty
{
    my ($self) = @_;
    my $size   = $self->size;

    if ($size == 0) { return 1;}
    if ($size <= 8) {
	if ($self =~ /^\s*$/) { return 1;}
    }

    # false
    return 0;
}


1;
