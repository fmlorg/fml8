#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::Messages;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
require Exporter;


=head1 NAME

FML::__HERE_IS_YOUR_MODULE_NAME__.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::__MODULE_NAME__.pm appeared in fml5.

=cut


@ISA       = qw(Exporter);
@EXPORT_OK = qw(Log);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    return bless {}, $type;
}


1;
