#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Auth.pm,v 1.35 2004/04/23 04:10:30 fukachan Exp $
#

package FML::Command::Auth;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $debug);
use Carp;


# XXX_LOCK_CHANNEL: auth_map_modify
my $lock_channel = "auth_map_modify";


=head1 NAME

FML::Command::Auth - authentication functions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=head2 reject()

dummy :-)

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: virtual reject handler, just return __LAST__ :-)
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: STR (__LAST__, a special upcall)
sub reject
{
    my ($self, $curproc, $optargs) = @_;

    return '__LAST__';
}


# Descriptions: permit anyone
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM
sub permit_anyone
{
    my ($self, $curproc, $optargs) = @_;

    return 1;
}


# Descriptions: permit if admin_member_maps has the sender
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM
sub permit_admin_member_maps
{
    my ($self, $curproc, $optargs) = @_;
    my $cred   = $curproc->{ credential };
    my $sender = $cred->sender();
    my $match  = $cred->is_privileged_member($sender);

    if ($match) {
	$curproc->log("found in admin_member_maps");
	return 1;
    }

    return 0;
}


# Descriptions: reject if the mail address looks like system accounts.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM or STR (__LAST__, a special upcall)
sub reject_system_special_accounts
{
    my ($self, $curproc, $optargs) = @_;
    my $cred   = $curproc->{ credential };
    my $sender = $cred->sender();
    my $match  = $cred->match_system_special_accounts($sender);

    if ($match) {
	$curproc->log("reject_system_special_accounts: matches the sender");
	return '__LAST__';
    }

    return 0;
}


=head2 check_admin_member_password($curproc, $optargs)

check the password if it is valid or not as an administrator.

=cut


# Descriptions: check the password if it is valid or not.
#    Arguments: OBJ($self)
#               HASH_REF($curproc)
#               HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM
sub check_admin_member_password
{
    my ($self, $curproc, $optargs) = @_;
    my $function = "check_admin_member_password";
    my $cred     = $curproc->{ credential };
    my $sender   = $cred->sender();
    my $config   = $curproc->config();
    my $status   = 0;

    # simple sanity check: verify non empty input or not?
    return 0 unless defined $optargs->{ address };
    return 0 unless $optargs->{ address };
    return 0 unless defined $optargs->{ password };
    return 0 unless $optargs->{ password };

    # get a set of address and password
    my $address  = $optargs->{ address }  || $sender;
    my $password = $optargs->{ password } || '';
    unless ($address && $password) {
	# XXX-TODO: please return error message.
	return 0;
    }

    # 1. validate address. address representation is restricted.
    # 2. but, password should be allowed arbitrary syntax.
    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    unless ($safe->regexp_match('address', $address)) {
	$curproc->logerror("FML::Command::Auth: unsafe address input");
	return 0;
    }
    my ($user, $domain) = split(/\@/, $address);

    # o.k. start ...
    $curproc->lock($lock_channel);

    # error details.
    my $user_entry_found = 0;
    my $password_match   = 0;

    # search $user in password database map, which has a hash of
    # { $user => $encrypted_passwrod }.
    my $maplist = $config->get_as_array_ref('admin_member_password_maps');
    for my $map (@$maplist) {
	use IO::Adapter;
	my $obj   = new IO::Adapter $map, $config;
	my $pwent = $obj->find( $user , { want => 'key,value', all => 1 });

	# if this $map has this $user entry,
	# try to check { user => password } relation.
	if (defined $pwent) {
	    use FML::Crypt;
	    my $crypt = new FML::Crypt;

	  PASSWORD_ENTRY:
	    for my $r (@$pwent) {
		my ($u, $p_infile) = split(/\s+/, $r);

		# 1.1 user match ? ($address syntax is checked above.)
		if ($cred->is_same_address($u, $address)) {
		    $user_entry_found = 1;

		    # 1.2 password match ?
		    my $p_input = $crypt->unix_crypt($password, $p_infile);
		    if ($p_infile eq $p_input) {
			if ($debug) {
			    $curproc->log("$function: password match");
			}
			$password_match = 1;
			$status = 1;
			last PASSWORD_ENTRY;
		    }
		}
            }
        }
    }

    $curproc->unlock($lock_channel);

    unless ($status) {
	# 1. user not found.
	unless ($user_entry_found) {
	    $curproc->logerror("$function: no such user");
	}
	# 2. user is found but password is wrong.
	else {
	    unless ($password_match) {
		$curproc->logerror("$function: password mismatch");
	    }
	}
    }
    return $status;
}


=head2 change_password($curproc, $command_args, $up_args)

    $up_args = {
	maplist  => $maps,
	address  => $address,
	password => $password,
    };

=cut


# Descriptions:
#    Arguments: OBJ($self)
#               OBJ($curproc) HASH_REF($command_args) HASH_REF($up_args)
# Side Effects: admin password modified.
# Return Value: NUM
sub change_password
{
    my ($self, $curproc, $command_args, $up_args) = @_;
    my $map      = $up_args->{ map };
    my $address  = $up_args->{ address  };
    my $password = $up_args->{ password };
    my $status   = 0;

    # crypt-fy password.
    use FML::Crypt;
    my $crypt = new FML::Crypt;
    my $cp    = $crypt->unix_crypt($password, $$);

    $curproc->lock($lock_channel);

    use IO::Adapter;
    my $obj = new IO::Adapter $map;
    if (defined $obj) {
	$obj->open();
	$obj->touch();

	# delete
	if ($obj->find( $address )) {
	    $obj->delete( $address );
	    if ($obj->error()) {
		$curproc->logerror("cannot delete $address from=$map");
	    }
	    else {
		$curproc->log("delete $address from=$map");
	    }
	}
	else {
	    $curproc->logerror("$address not found");
	}

	# add
	$obj->error_clear();
	$obj->add( $address, [ $cp, "UNIX_CRYPT" ] ) && $status++;
	if ($obj->error()) {
	    $curproc->logerror("cannot add $address to=$map");
	}
	else {
	    $curproc->log("add password for $address to=$map");
	}

	$obj->close();
    }

    $curproc->unlock($lock_channel);

    return $status;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Auth first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
