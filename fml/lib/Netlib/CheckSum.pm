#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Netlib::CheckSum;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;

@ISA       = qw(Exporter);

sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
  }


sub md5
  {
}


=head1 NAME

Netlib::CheckSum.pm - what is this


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

Netlib::CheckSum.pm appeared in fml5.

=cut


1;
