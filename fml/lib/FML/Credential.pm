#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Credential.pm,v 1.12 2001/06/29 05:57:32 fukachan Exp $
#

package FML::Credential;

use strict;
use vars qw(%Credential @ISA @EXPORT @EXPORT_OK);
use Carp;
use ErrorStatus qw(errstr error error_set error_clear);

=head1 NAME

FML::Credential - authenticate the mail sender

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


=head2 C<is_same_address($addr1, $addr2 [, $level])>

return 1 if C<$addr1> and C<$addr2> looks same within some ambiguity.
The ambiguity is followed by these rules.

1. C<user> part must be the same case sensitively.

2. C<domain> part is case insensitive by definition of C<DNS>.

3. C<domain> part is the same from the top C<gTLD> layer to
   C<$level>-th sub domain level.


   XXX RULE 3 IS NOT YET IMPLEMENTED


=cut

sub is_same_address
{
    my ($self, $xaddr, $yaddr, $level) = @_;
    my ($xuser, $xdomain) = split(/\@/, $xaddr);
    my ($yuser, $ydomain) = split(/\@/, $yaddr);

    # rule 1
    if ($xuser ne $yuser) { return 0;}

    # rule 2
    if ("\L$xdomain\E" eq "\L$ydomain\E") { return 1;}

    # rule 3: not yet

    0;
}


=head2 C<is_member($curproc, $args)>

return 1 if the sender is a ML member.
return 0 if not.

=cut


# Descriptions: 
#    Arguments: $self $curproc $args
# Side Effects: 
# Return Value: none
sub is_member
{
    my ($self, $curproc, $args) = @_;
    my $status = 0;

    my $member_maps = $curproc->{ config }->{ member_maps };
    my $address = $curproc->{'credential'}->{'sender'};
    my ($user, $domain) = split(/\@/, $address);

    use IO::Adapter;

  MAP:
    for my $map (split(/\s+/, $member_maps)) {
	if (defined $map) {
	    $status = $self->has_address_in_map($map, $address);
	    last MAP if $status;
	}
    }

    return $status; # found if ($status == 1).
}


sub has_address_in_map
{
    my ($self, $map, $address) = @_;
    my $status = 0;

    my ($user, $domain) = split(/\@/, $address);

    use IO::Adapter;
    my $obj = new IO::Adapter $map;

    # 1. get all entries match /^$user/ from $map.
    my $addrs = $obj->find( $user , { all => 1 });

    # 2. try each address in the result matches $address to check.
    if (defined $addrs) {
      LOOP:
	for my $x (@$addrs) {
	    my ($r) = split(/\s+/, $x);

	    # 3. is_same_address() conceals matching algorithm details.
	    if ($self->is_same_address($r, $address)) {
		$status = 1; # found
		last LOOP;
	    }
	}
    }

    unless ($status) {
	$self->error_set("user=$user domain=$domain not found");
    }

    return $status;
}



=head2 C<match_system_accounts($curproc, $args)>

C<sender> ( == $self->sender() ) matches a system account or not.
The system accounts are given as 

     $curproc->{ config }->{ system_accounts }. 

=cut


sub match_system_accounts
{
    my ($self, $curproc, $args) = @_;
    my $config = $curproc->{ config };

    # compare $user part of the sender address
    my ($user, $domain) = split(/\@/, $self->sender());

    # compare $user part with e.g. root, postmaster, ...
    # XXX always case INSENSITIVE
    for my $addr (split(/\s+/, $config->{ system_accounts })) {
	if ($user =~ /^${addr}$/i) { return $addr;}
    }

    return '';
}


=head2 C<sender()>

return the mail address of the mail sender who kicks off this fml
process.

=cut

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

   XXX NUKE THIS ?

=head2 C<set(key, value)>

   XXX NUKE THIS ?

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
