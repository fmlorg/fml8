#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Messages.pm,v 1.8 2001/05/28 16:17:13 fukachan Exp $
#

package FML::Messages;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;


=head1 NAME

FML::Messages - manipulate fml system messages

=head1 SYNOPSIS

   use FML::Messages;

=head1 DESCRIPTION

C<FML::Messages> is a wrapper.
It tranlates the error message to specifield language.

=head1 METHODS

   not implemented yet...

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    return bless {}, $type;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Messages appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
