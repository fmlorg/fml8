#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: get.pm,v 1.3 2001/04/03 09:45:42 fukachan Exp $
#

package FML::Command::get;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Command::get - what is this

=head1 SYNOPSIS

not yet implemented

=head1 DESCRIPTION

=head1 METHODS

=head2 C<new()>

=cut


require Exporter;
@ISA = qw(Exporter);


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head1 AUTHOR

__YOUR_NAME__

=head1 COPYRIGHT

Copyright (C) 2001 __YOUR_NAME__

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Command::get appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
