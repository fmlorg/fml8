#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Credential.pm,v 1.22 2002/03/22 11:36:05 fukachan Exp $
#

package FML::Credential;

use strict;
use vars qw(%Credential @ISA @EXPORT @EXPORT_OK);
use Carp;
use ErrorStatus qw(errstr error error_set error_clear);

=head1 NAME

FML::Credential - functions to authenticate the mail sender

=head1 SYNOPSIS

   use FML::Credential;

   # get the mail sender
   my $sender = FML::Credential->sender;

=head1 DESCRIPTION

a collection of utilitity functions to authenticate the sender who
kicks off this mail.

=head2 User credential information

C<%Credential> information is unique in one fml process.
So this hash is accessible in public.

=head1 METHODS

=head2 C<new()>

bind $self to the module internal C<\%Credential> hash and return the
has reference as an object.

=cut


# Descriptions: usual constructor
#               bind $self ($me) to \%Credential, so
#               you can access the same \%Credential through this object.
#    Arguments: OBJ($self)
# Side Effects: bind $self ($me) to \%Credential
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%Credential;

    # default comparison level
    set_compare_level( $me, 3 );

    return bless $me, $type;
}


sub DESTROY {}


=head2 C<is_same_address($addr1, $addr2 [, $level])>

return 1 (same ) or 0 (different).
It returns 1 if C<$addr1> and C<$addr2> looks same within some
ambiguity.  The ambiguity is defined by the following rules:

1. C<user> part must be the same case sensitively.

2. C<domain> part is case insensitive by definition of C<DNS>.

3. C<domain> part is the same from the top C<gTLD> layer to
   C<$level>-th sub domain level.

            .jp
           d.jp
         c.d.jp
           ......

By default we compare the last (top) C<3> level.
For example, consider these two addresses:

            rudo@nuinui.net
            rudo@sapporo.nuinui.net

These addresses differs. But

            rudo@fml.nuinui.net
            rudo@sapporo.fml.nuinui.net

are same since the last 3 top level domains are same.

=cut


# Descriptions: compare whether the given addresses are same or not.
#    Arguments: OBJ($self) STR($xaddr) STR($xaddr) NUM($max_level)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_same_address
{
    my ($self, $xaddr, $yaddr, $max_level) = @_;
    my ($xuser, $xdomain) = split(/\@/, $xaddr);
    my ($yuser, $ydomain) = split(/\@/, $yaddr);
    my $level = 0;
    $max_level = $max_level || $self->{ _max_level } || 3;

    # rule 1
    if ($xuser ne $yuser) { return 0;}

    # rule 2
    if ("\L$xdomain\E" eq "\L$ydomain\E") { return 1;}

    # rule 3: compare a.b.c.d.jp in reverse order
    my (@xdomain) = reverse split(/\./, $xdomain);
    my (@ydomain) = reverse split(/\./, $ydomain);
    for (my $i = 0; $i < $#xdomain; $i++) {
	my $xdomain = $xdomain[ $i ];
	my $ydomain = $ydomain[ $i ];
	if ("\L$xdomain\E" eq "\L$ydomain\E") { $level++;}
    }

    if ($level >= $max_level) { return 1;}

    # fail
    return 0;
}


=head2 C<is_member($curproc, $args)>

return 1 if the sender is a ML member.
return 0 if not.

=cut


# Descriptions: sender of the current process is an ML member or not.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_member
{
    my ($self, $curproc, $args) = @_;
    my $member_maps = $curproc->{ config }->{ member_maps };
    my $address = $args->{ address } || $curproc->{'credential'}->{'sender'};
    my $status  = 0;

    $self->_is_member($curproc, $args, {
	address     => $address,
	member_maps => $member_maps,
    });
}


# Descriptions: sender of the current process is an ML administrator ?
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_privileged_member
{
    my ($self, $curproc, $args) = @_;
    my $member_maps = $curproc->{ config }->{ admin_member_maps };
    my $address = $args->{ address } || $curproc->{'credential'}->{'sender'};

    $self->_is_member($curproc, $args, {
	address     => $address,
	member_maps => $member_maps,
    });
}


# Descriptions: sender of the current process is an ML member or not.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_member
{
    my ($self, $curproc, $args, $optargs) = @_;
    my $member_maps = $optargs->{ member_maps };
    my $address     = $optargs->{ address };
    my $status      = 0;
    my $user        = '';
    my $domain      = '';

    if (defined $address) {
	($user, $domain) = split(/\@/, $address);
    }
    else {
	return $status;
    }

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


# Descriptions: $map contains $address or not in some ambiguity
#               by is_same_address().
#    Arguments: OBJ($self) STR($map) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub has_address_in_map
{
    my ($self, $map, $address) = @_;
    my ($user, $domain) = split(/\@/, $address);
    my $status          = 0;

    use IO::Adapter;
    my $obj = new IO::Adapter $map;

    # 1. get all entries match /^$user/ from $map.
    my $addrs = $obj->find( $user , { want => 'key', all => 1 });

    # 2. try each address in the result matches $address to check.
    if (defined $addrs) {
      LOOP:
	for my $r (@$addrs) {
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


# Descriptions: sender of this process is a system account ?
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: STR
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

# Descriptions: return the mail sender
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR(mail address)
sub sender
{
    my ($self) = @_;
    $Credential{ sender };
}


=head2 C<set_compare_level( $level )>

set C<level>, how many sub-domains from top level we compare, in
C<in_same_address()> address comparison.

=head2 C<get_compare_level()>

get level in C<in_same_address()> address comparison.
return the number of C<level>.

=cut


# Descriptions: set address comparison level
#    Arguments: OBJ($self) NUM($level)
# Side Effects: change private variables in object
# Return Value: NUM
sub set_compare_level
{
    my ($self, $level) = @_;
    $self->{ _max_level } = $level;
}


# Descriptions: return address comparison level
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_compare_level
{
    my ($self) = @_;
    return (defined $self->{ _max_level } ? $self->{ _max_level } : undef);
}



=head2 C<get(key)>

   XXX NUKE THIS ?

=head2 C<set(key, value)>

   XXX NUKE THIS ?

=cut


# Descriptions: get value for the specified key
#    Arguments: OBJ($self) STR($key)
# Side Effects: change object
# Return Value: STR
sub get
{
    my ($self, $key) = @_;

    if (defined $self->{ $key }) {
	return $self->{ $key };
    }
    else {
	return '';
    }
}


# Descriptions: set value for $key to be $value
#    Arguments: OBJ($self) STR($key) STR($value)
# Side Effects: none
# Return Value: STR
sub set
{
    my ($self, $key, $value) = @_;
    $self->{ $key } = $value;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Credential appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
