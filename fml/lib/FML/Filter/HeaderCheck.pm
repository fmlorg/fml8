#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: HeaderCheck.pm,v 1.1.1.1 2001/03/28 15:13:31 fukachan Exp $
#

package FML::Filter::HeaderCheck;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

FML::Filter::HeaderCheck - filter by mail header content

=head1 SYNOPSIS

=head1 DESCRIPTION

C<FML::Filter::HeaderCheck> is a collectoin of filter rules based on
mail header content.

=head1 METHODS

=head2 C<new()>

usual constructor.

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}



=head2 C<header_check($curproc, $args)>

entrance to the header check routines.
C<fml process> to need this function kicks off fileter rules 
through C<header_check()>.

Filter rules are applied to the incoming message from STDIN, 

   $curproc->{ incoming_message }->{ header }.

=cut


sub header_check
{
    my ($self, $curproc, $args) = @_;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Filter::HeaderCheck appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
