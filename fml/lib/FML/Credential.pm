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


=head1 NAME

FML::Credential - authenticate the mail sender is a ML member or not

=head1 SYNOPSIS

   use FML::Credential;

   # get the mail sender
   my $sender = FML::Credential->sender;

=head1 DESCRIPTION

a collection of utilitity functions to authenticate the sender who
kicks off this mail.

=head1 METHODS

=head2 C<new()>

bind \%Credential to $self and return it as an object.

=cut


# Descriptions: usual constructor
#               bind $self ($me) to \%Credential, so
#               you can access the same \%Credential through this object.
#    Arguments: $self
# Side Effects: bind $self ($me) to \%Credential
# Return Value: object
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%Credential;
    return bless $me, $type;
}


sub DESTROY {}


=head2 C<is_member()>

not yet implemented

=head2 C<sender()>

return the mail address of the mail sender who kicks off this fml
process.

=cut


# Descriptions: 
#    Arguments: $self $args
# Side Effects: 
# Return Value: none
sub is_member { 1;}


# Descriptions: returh the mail sender
#    Arguments: $self
# Side Effects: none
# Return Value: mail address
sub sender
{
    my ($self) = @_;
    $Credential{ sender };
}


=head2 C<get(key)>

=head2 C<set(key, value)>

=cut


# Descriptions: 
#    Arguments: $self key
# Side Effects: none
# Return Value: string
sub get
{
    my ($self, $key) = @_;
    $self->{ $key };	
}


# Descriptions: 
#    Arguments: $self key value
# Side Effects: none
# Return Value: string
sub set
{
    my ($self, $key, $value) = @_;
    $self->{ $key } = $value;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

FML::Credential appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
