#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Credential.pm,v 1.71 2008/06/28 20:05:56 fukachan Exp $
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

FML::Credential - functions to authenticate the mail sender.

=head1 SYNOPSIS

   use FML::Credential;

   # get the mail sender
   my $cred   = new FML::Credential;
   my $sender = $cred->sender;

=head1 DESCRIPTION

This class provides a collection of utilitity functions to
authenticate the sender of the message which kicks off this process.

=head2 User credential information

C<%Credential> information is unique in one fml process.
So this hash is accessible in public.

=head1 METHODS

=head2 new()

constructor. It bind $self to the module internal C<\%Credential> hash
and return the hash reference as an object.

ASSMPUTION:

We assume one process has one credential since the mail sender must be
unique. It must be one credential even if context switching of
processing mailing list occurs.

=cut


# Descriptions: constructor.
#               bind $self ($me) to \%Credential, so
#               you can access the same \%Credential through this object.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: bind $self ($me) to \%Credential.
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = \%Credential;
    my $config = $curproc->config();
    my $level  =
	$config->{ address_compare_function_domain_matching_level } || 3;

    # default comparison level
    set_compare_level( $me, $level );

    _reconfigure($me);

    # hold pointer to $curproc
    $me->{ _curproc } = $curproc if defined $curproc;

    return bless $me, $type;
}


# Descriptions: analyze $config.
#    Arguments: OBJ($self)
# Side Effects: update $self.
# Return Value: none
sub _reconfigure
{
    my ($self)  = @_;
    my $curproc = $self->{ _curproc } || undef;

    if (defined $curproc) {
	my $config = $curproc->config();
	my $actype = $config->{ address_compare_function_type };

	# user address check
	if ($config->yes('use_address_compare_function')) {
	    $self->{ _use_address_compare_function } = 1;
	}
	else {
	    $self->{ _use_address_compare_function } = 0;
	}

	# case insensitive for backward compatibility by default.
	if ($actype eq 'user_part_case_insensitive' ||
	    $actype eq 'case_insensitive') {
	    $self->{ _user_part_case_sensitive } = 0;
	}
	# case sensitive for user part comparison.
	elsif ($actype eq 'user_part_case_sensitive' ||
	       $actype eq 'case_sensitive') {
	    $self->{ _user_part_case_sensitive } = 1;
	}
	# case-insensitive by default for backward compatibility.
	else {
	    $self->{ _user_part_case_sensitive } = 0;
	}
    }
}


# Descriptions: dummy.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub DESTROY {}


=head1 ACCESS METHODS

=head2 set_user_part_case_sensitive()

compare user part case sensitively by default.

=head2 set_user_part_case_insensitive()

compare user part case insensitively.

=cut


# Descriptions: compare user part case sensitively.
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


# Descriptions: whether we should handle user part case insensitively.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: none
sub is_user_part_case_sensitive
{
    my ($self) = @_;
    $self->{ _user_part_case_sensitive } ? 1 : 0;
}


=head2 is_same_address($addr1, $addr2, $max_level)

return 1 (same) or 0 (different).
It returns 1 if C<$addr1> and C<$addr2> looks same within some
ambiguity.  The ambiguity is defined by the following rules:

1. C<user> part must be same case-sensitively.

2. C<domain> part is same case-insensitively by definition of C<DNS>.

3. C<domain> part is same case-insensitively
   from the top C<gTLD> layer to C<$level>-th sub domain level.

            .jp
           d.jp
         c.d.jp
           ......

By default we compare the last (top) C<3> level.
For example, consider these two addresses:

            rudo@nuinui.net
            rudo@sapporo.nuinui.net

These addresses differ. But the following addresses

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

    $self->_reconfigure();

    # always same if address_check function disabled.
    unless ($self->{ _use_address_compare_function }) { return 1; }

    # both should be defined !
    unless (defined($xaddr) && defined($yaddr)) {
	return 0;
    }

    my ($xuser, $xdomain) = split(/\@/, $xaddr);
    my ($yuser, $ydomain) = split(/\@/, $yaddr);
    my $level             = 0;
    my $is_case_sensitive = $self->is_user_part_case_sensitive();

    # the max recursive level in comparison
    $max_level = $max_level || $self->{ _max_level } || 3;

    # rule 1: case sensitive
    print STDERR "1. check only account part\n" if $debug;
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
    print STDERR "2. eq domain ?\n" if $debug;
    if ("\L$xdomain\E" eq "\L$ydomain\E") { return 1;}

    # rule 3: compare a.b.c.d.jp in reverse order
    print STDERR "3. compare each part in domain ?\n" if $debug;
    my (@xdomain) = reverse split(/\./, $xdomain);
    my (@ydomain) = reverse split(/\./, $ydomain);
    for (my $i = 0; $i < $#xdomain; $i++) {
	my $xdomain = $xdomain[ $i ];
	my $ydomain = $ydomain[ $i ];
	print STDERR "    $xdomain eq $ydomain ?\n" if $debug;
	if ("\L$xdomain\E" eq "\L$ydomain\E") { $level++;}
    }

    print STDERR "result: $level >= $max_level ?\n" if $debug;
    if ($level >= $max_level) { return 1;}

    # fail
    return 0;
}


=head2 is_same_domain($xdomain, $ydomain)

check if $xdomain and $ydomain are same or not case-insensitively.

=cut


# Descriptions: check if the specified domains are same or not
#               case-insensitively.
#    Arguments: OBJ($self) STR($xdomain) STR($ydomain)
# Side Effects: none
# Return Value: NUM
sub is_same_domain
{
    my ($self, $xdomain, $ydomain) = @_;

    if ("\L$xdomain\E" eq "\L$ydomain\E") {
	return 1;
    }
    else {
	return 0;
    }
}


=head2 is_ml_domain($address)

check if the domain part of $address matches exact $ml_domain (our
default domain) or not. return 1 if matched or 0 not.

XXX o.k. to support only exact match ?

=cut


# Descriptions: check if the domain part of $address matches exact $ml_domain.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_ml_domain
{
    my ($self, $address) = @_;
    my $curproc   = $self->{ _curproc };
    my $ml_domain = $curproc->ml_domain();

    if ($address && $ml_domain) {
	if ($address =~ /\@$ml_domain$/i) { # domain is case insensitive.
	    return 1;
	}
    }

    return 0;
}


=head2 is_member($address)

return 1 if the sender <$address> is an ML member.
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
    my $config      = $curproc->config();
    my $member_maps = $config->get_as_array_ref('member_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $member_maps,
    });
}


=head2 is_privileged_member($address)

return 1 if the sender <$address> is an ML administrator.
return 0 if not.

=cut


# Descriptions: sender of the current process is an ML administrator ?
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_privileged_member
{
    my ($self, $address) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();
    my $member_maps = $config->get_as_array_ref('admin_member_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $member_maps,
    });
}


=head2 is_recipient($address)

return 1 if the sender <$address> is an ML recipient.
return 0 if not.

=cut


# Descriptions: sender of the current process is an ML recipient or not.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_recipient
{
    my ($self, $address) = @_;
    my $curproc        = $self->{ _curproc };
    my $config         = $curproc->config();
    my $recipient_maps = $config->get_as_array_ref('recipient_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $recipient_maps,
    });
}


=head2 is_moderator_member($address)

return 1 if the sender <$address> is an ML moderator.
return 0 if not.

=cut


# Descriptions: sender of the current process is an ML moderator member or not.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_moderator_member
{
    my ($self, $address) = @_;
    my $curproc     = $self->{ _curproc };
    my $config      = $curproc->config();
    my $member_maps = $config->get_as_array_ref('moderator_member_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $member_maps,
    });
}


=head2 is_spammer($address)

return 1 if the sender <$address> is a spammer.
return 0 if not.

=cut


# Descriptions: sender of the current process is a spammer or not.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_spammer
{
    my ($self, $address) = @_;
    my $curproc      = $self->{ _curproc };
    my $config       = $curproc->config();
    my $spammer_maps = $config->get_as_array_ref('spammer_maps');

    $self->_is_member({
	address     => $address,
	member_maps => $spammer_maps,
    });
}


# Descriptions: check the specified address is included in the specified maps.
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
	# XXX-TODO: used ?
	($user, $domain) = split(/\@/, $address);
    }
    else {
	return $status;
    }

  MAP:
    for my $map (@$member_maps) {
	if (defined $map) {
	    # XXX-TODO: has_ is o.k.? hmmm, find_address_in_map() ?
	    $status = $self->has_address_in_map($map, $config, $address);
	    last MAP if $status;
	}
    }

    return $status; # found if ($status == 1).
}


# Descriptions: check $map contains $address or not within some ambiguity
#               by is_same_address().
#    Arguments: OBJ($self) STR($map) HASH_REF($config)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_valid_map
{
    my ($self, $map, $config) = @_;
    my $status          = 0;
    my $curproc         = $self->{ _curproc };

    use IO::Adapter;
    my $io = new IO::Adapter $map, $config;
    my $rh = $io->open( { flag => 'r' } );
    if (defined $rh) {
	$rh->close();
	return 1;
    }
    else {
	return 0;
    }
}


# Descriptions: check $map contains $address or not within some ambiguity
#               by is_same_address().
#    Arguments: OBJ($self) STR($map) HASH_REF($config) STR($address)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub has_address_in_map
{
    my ($self, $map, $config, $address) = @_;
    my ($user, $domain) = split(/\@/, $address);
    my $status          = 0;
    my $curproc         = $self->{ _curproc };

    # reset the matched result;
    $self->_save_address('');

    use IO::Adapter;
    my $obj = new IO::Adapter $map, $config;

    # 1. get all entries match /^$user/ from $map.
    # XXX-TODO: case sensitive / insensitive ?
    if ($debug) {
	print STDERR "find( $user , { want => 'key', all => 1 });\n";
    }

    # $curproc->lock($lock_channel);   # READER LOCK
    my $_user = quotemeta($user);
    my $addrs = $obj->find($_user ,
			   { want => 'key', all => 1, hints => [ $address ] });
    # $curproc->unlock($lock_channel); # READER LOCK

    if (ref($addrs) && $debug) {
	print STDERR "cred: match? [ @$addrs ]\n";
    }

    # 2. try each address in the result matches $address to check.
    if (defined $addrs) {
      ADDR:
	for my $_addr (@$addrs) {
	    # 3. is_same_address() conceals matching algorithm details.
	    print STDERR "is_same_address($_addr, $address)\n" if $debug;
	    if ($self->is_same_address($_addr, $address)) {
		print STDERR "\tmatch!\n" if $debug;
		$status = 1; # found
		$self->_save_address($_addr);
		last ADDR;
	    }
	    else {
		print STDERR "\tnot match!\n" if $debug;
	    }
	}
    }

    unless ($status) {
	$user   ||= '';
	$domain ||= '';
	$self->error_set("user=$user domain=$domain not found");
    }

    return $status;
}


=head2 matched_address()

return the last matched address.

=cut


# XXX-TODO: matched_address() returns the last matched one but
# XXX-TODO: wrong if x@A.B and x@A.b matches.


# Descriptions: return the last matched address.
#               used together with has_address_in_map().
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR
sub matched_address
{
    my ($self) = @_;
    return $self->_get_address();
}


# Descriptions: save the last matched address.
#    Arguments: OBJ($self) STR($address)
# Side Effects: update $self->{ _last_matched_address };
# Return Value: STR
sub _save_address
{
    my ($self, $address) = @_;
    $self->{ _last_matched_address } = $address if defined $address;
}


# Descriptions: return the last matched address.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: STR
sub _get_address
{
    my ($self, $address) = @_;

    if (defined $self->{ _last_matched_address }) {
	return $self->{ _last_matched_address };
    }

    return '';
}


=head2 match_system_special_accounts($addr)

check is the specified C<addr> matches a system account or not.
The system accounts are given as

     $curproc->config()->{ system_special_accounts }.

=cut


# Descriptions: check if $addr matches a system account ?
#               return the matched address or NULL.
#    Arguments: OBJ($self) STR($addr)
# Side Effects: none
# Return Value: STR
sub match_system_special_accounts
{
    my ($self, $addr) = @_;
    my $curproc = $self->{ _curproc };
    my $config  = $curproc->config();

    # compare $user part of the sender address
    my ($user, $domain) = split(/\@/, $addr);

    # compare $user part with e.g. root, postmaster, ...
    # XXX always case INSENSITIVE
    my $accounts = $config->get_as_array_ref('system_special_accounts');
    for my $addr (@$accounts) {
	if ($user =~ /^${addr}$/i) { return $addr;}
    }

    return '';
}


=head2 sender()

same as get_sender().

=head2 set_sender()

overwrite sender info in credential object.

=head2 get_sender()

return the mail address of the mail sender who kicks off this fml
process.

=cut


# Descriptions: return the mail sender.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR(mail address)
sub sender
{
    my ($self) = @_;
    $self->get_sender();
}


# Descriptions: set the mail sender.
#    Arguments: OBJ($self) STR($address)
# Side Effects: none
# Return Value: none
sub set_sender
{
    my ($self, $address) = @_;

    if (defined $address && $address) {
	$Credential{ sender } = $address;
    }
    else {
	croak("wrong credential usage");
    }
}


# Descriptions: return the mail sender.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: STR(mail address)
sub get_sender
{
    my ($self) = @_;

    return( $Credential{ sender } || '' );
}


=head2 set_compare_level( $level )

set C<level>, how many sub-domains from top level we compare.
This parameter is in C<in_same_address()> address comparison.

=head2 get_compare_level()

get level in C<in_same_address()> address comparison.
return the number of C<level>.

=cut


# Descriptions: set address comparison level.
#    Arguments: OBJ($self) NUM($level)
# Side Effects: change private variables in object.
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


# Descriptions: return address comparison level.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: NUM
sub get_compare_level
{
    my ($self) = @_;
    return (defined $self->{ _max_level } ? $self->{ _max_level } : undef);
}



=head2 get(key)

   XXX NUKE THIS ?

=head2 set(key, value)

   XXX NUKE THIS ?

=cut


# XXX-TODO: remove get() and set(), which are not used ?


# Descriptions: get value for the specified key.
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


# Descriptions: set value for $key to be $value.
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
    my $fp   = $ARGV[2] || "has_address_in_map";

    use FML::Process::Debug;
    my $curproc = new FML::Process::Debug;
    my $obj     = new FML::Credential $curproc;

    $debug = 1;
    if ($fp eq "has_address_in_map") {
	print STDERR "has_address_in_map( $file, {}, $addr ) ...\n";
	print STDERR $obj->has_address_in_map( $file, {}, $addr );
	print STDERR "\n";
    }
    elsif ($obj->can($fp)) {
	print STDERR "\$obj->$fp($addr);\n";
	my $status = $obj->$fp($addr);
	print STDERR "status: $status\n";
    }
    else {
	croak("no such function: $fp");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Credential first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
