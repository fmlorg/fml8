#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package FML::MemberControl;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::MemberControl - controller

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut

use FML::Command::add;
use FML::Command::delete;

@ISA = qw(FML::Command::add FML::Command::delete);

sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::MemberControl appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
