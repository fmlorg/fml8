#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Credential.pm,v 1.40 2003/01/11 06:58:44 fukachan Exp $
#

package FML::Credential;
use strict;
use Carp;
use vars qw(%Credential @ISA @EXPORT @EXPORT_OK);
use ErrorStatus qw(errstr error error_set error_clear);

#
# XXX-TODO: methods of FML::Credential validates input always ?
#

my $debug = 0;


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
hash reference as an object.

=cut


# Descriptions: constructor.
#               bind $self ($me) to \%Credential, so
#               you can access the same \%Credential through this object.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: bind $self ($me) to \%Credential
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%Credential;

    # default comparison level
    set_compare_level( $me, 3 );

    # case sensitive for user part comparison.
    $me->{ _user_part_case_sensitive } = 1;

    # hold pointer to $curproc
    $me->{ _curproc } = $curproc if defined $curproc;

    return bless $me, $type;
}


# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


=head1 ACCESS METHODS

=head2 set_user_part_case_sensitive()

compare user part case sensitively (default).

=head2 set_user_part_case_insensitive()

compare user part case insensitively.

=cut


# Descriptions: compare user part case sensitively (default)
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub set_user_part_case_sensitive
{
    my ($self) = @_;
    $self->{ _user_part_case_sensitive } = 1;
}


# Descriptions: compare user part case insensitively.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub set_user_part_case_insensitive
{
    my ($self) = @_;
    $self->{ _user_part_case_sensitive } = 0;
}


=head2 C<is_same_address($addr1, $addr2 [, $level])>

return 1 (same) or 0 (different).
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
#    Arguments: OBJ($self) STR($xaddr) STR($yaddr) NUM($max_level)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_same_address
{
    my ($self, $xaddr, $yaddr, $max_level) = @_;

    # both should be defined !
    unless (defined($xaddr) && defined($yaddr)) {
	return 0;
    }

    my ($xuser, $xdomain) = split(/\@/, $xaddr);
    my ($yuser, $ydomain) = split(/\@/, $yaddr);
    my $level             = 0;
    my $is_case_sensitive = $self->{ _user_part_case_sensitive };

    # the max recursive level in comparison
    $max_level = $max_level || $self->{ _max_level } || 3;

    # rule 1: case sensitive
    if ($is_case_sensitive) {
	if ($xuser ne $yuser) { return 0;}
    }
    else {
	if ("\L$xuser\E" ne "\L$yuser\E") { return 0;}
    }

    # XXX adjust to avoid undefined warning.
    $xdomain ||= ''; 
    $ydomain ||= ''; 

    # rule 2: case insensitive
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

return 1 if the sender is an ML member.
return 0 if not.

=cut


# Descriptions: sender of the current process is an ML member or not.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_member
{
    my ($self, $address) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->{ config };
    my $member_maps = $config->get_as_array_ref('member_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $member_maps,
    });
}


# Descriptions: sender of the current process is an ML administrator ?
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_privileged_member
{
    my ($self, $address) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->{ config };
    my $member_maps = $config->get_as_array_ref('admin_member_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $member_maps,
    });
}


# Descriptions: sender of the current process is an ML recipient or not.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_recipient
{
    my ($self, $address) = @_;
    my $curproc        = $self->{ _curproc };
    my $config         = $curproc->{ config };
    my $recipient_maps = $config->get_as_array_ref('recipient_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $recipient_maps,
    });
}


# Descriptions: sender of the current process is an ML member or not.
#    Arguments: OBJ($self) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _is_member
{
    my ($self, $optargs) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();
    my $status  = 0;
    my $user    = '';
    my $domain  = '';

    # cheap sanity
    return 0 unless defined $optargs->{ member_maps };
    return 0 unless defined $optargs->{ address };

    my $member_maps = $optargs->{ member_maps };
    my $address     = $optargs->{ address };

    if (defined $address) {
	($user, $domain) = split(/\@/, $address);
    }
    else {
	return $status;
    }

    use IO::Adapter;

  MAP:
    for my $map (@$member_maps) {
	if (defined $map) {
	    $status = $self->has_address_in_map($map, $config, $address);
	    last MAP if $status;
	}
    }

    return $status; # found if ($status == 1).
}


# Descriptions: $map contains $address or not in some ambiguity
#               by is_same_address().
#    Arguments: OBJ($self) STR($map) HASH_REF($config) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub has_address_in_map
{
    my ($self, $map, $config, $address) = @_;
    my ($user, $domain) = split(/\@/, $address);
    my $status          = 0;

    use IO::Adapter;
    my $obj = new IO::Adapter $map, $config;

    # 1. get all entries match /^$user/ from $map.
    # XXX-TODO: case sensitive / insensitive ?
    if ($debug) {
	print STDERR "find( $user , { want => 'key', all => 1 });\n";
    }
    my $addrs = $obj->find( $user , { want => 'key', all => 1 });

    if (ref($addrs) && $debug) {
	print STDERR "cred: match? [ @$addrs ]\n";
    }

    # 2. try each address in the result matches $address to check.
    if (defined $addrs) {
      LOOP:
	for my $r (@$addrs) {
	    # 3. is_same_address() conceals matching algorithm details.
	    print STDERR "is_same_address($r, $address)\n" if $debug;
	    if ($self->is_same_address($r, $address)) {
		print STDERR "\tmatch!\n" if $debug;
		$status = 1; # found
		last LOOP;
	    }
	    else {
		print STDERR "\tnot match!\n" if $debug;
	    }
	}
    }

    unless ($status) {
	$domain ||= ''; 
	$self->error_set("user=$user domain=$domain not found");
    }

    return $status;
}


=head2 C<match_system_accounts($addr)>

C<addr> matches a system account or not.
The system accounts are given as

     $curproc->{ config }->{ system_accounts }.

=cut


# Descriptions: check if $addr matches a system account ?
#               return the matched address or NULL.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub match_system_accounts
{
    my ($self, $addr) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->{ config };

    # compare $user part of the sender address
    my ($user, $domain) = split(/\@/, $addr);

    # compare $user part with e.g. root, postmaster, ...
    # XXX always case INSENSITIVE
    my $accounts = $config->get_as_array_ref('system_accounts');
    for my $addr (@$accounts) {
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

    if ($level =~ /^\d+$/) {
	$self->{ _max_level } = $level;
    }
    else {
	croak("set_compare_level: invalid input ($level)");
    }
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

# XXX-TODO: remove get() and set(), which are not used ?


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
	warn("Credential::get: invalid input { key=$key }");
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

    if (defined $value) {
	$self->{ $key } = $value;
    }
    else {
	croak("set: invalid input { $key => $value }");
    }
}


#
# debug
#
if ($0 eq __FILE__) {
    my $file = $ARGV[0];
    my $addr = $ARGV[1];
    my $obj  = new FML::Credential;

    $debug = 1;
    print STDERR "has_address_in_map( $file, {}, $addr ) ...\n";
    print STDERR $obj->has_address_in_map( $file, {}, $addr );
    print STDERR "\n";
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Credential first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
