#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Auth.pm,v 1.8 2002/06/01 04:57:51 fukachan Exp $
#

package FML::Command::Auth;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use FML::Log qw(Log LogWarn LogError);

# always use this module's crypt
BEGIN { $Crypt::UnixCrpyt::OVERRIDE_BUILTIN = 1 }
use Crypt::UnixCrypt;


=head1 NAME

FML::Command::Auth - authentication functions

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head2 new()

=head2 reject()

return 0 :-) (dummy)

=cut


# Descriptions: ordinary constructor
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


# Descriptions: virtual reject handler, just return 0 :-)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub reject
{
    my ($self, $curproc, $args, $optargs) = @_;

    return '__LAST__';
}


# Descriptions: permit anyone
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub permit_anyone
{
    my ($self, $curproc, $args, $optargs) = @_;

    return 1;
}


# Descriptions: permit if admin_member_maps has the sender
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($args) HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM
sub permit_admin_member_maps
{
    my ($self, $curproc, $args, $optargs) = @_;
    my $cred  = $curproc->{ credential };
    my $match = $cred->is_privileged_member($curproc, $args);

    if ($match) {
	Log("found in admin_member_maps");
	return 1;
    }

    return 0;
}


# Descriptions: virtual reject handler, just return 0 :-)
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM
sub reject_system_accounts
{
    my ($self, $curproc, $args, $optargs) = @_;
    my $cred  = $curproc->{ credential };
    my $match = $cred->match_system_accounts($curproc, $args);

    if ($match) {
	Log("reject_system_accounts: matches the sender");
	return '__LAST__';
    }

    return 0;
}


=head2 check_admin_member_password($curproc, $args, $optargs)

check the password if it is valid or not.

=cut


# Descriptions: check the password if it is valid or not.
#    Arguments: OBJ($self)
#               HASH_REF($curproc)
#               HASH_REF($args)
#               HASH_REF($optargs)
# Side Effects: none
# Return Value: NUM
sub check_admin_member_password
{
    my ($self, $curproc, $args, $optargs) = @_;
    my $config   = $curproc->{ config };
    my $maplist  = $config->get_as_array_ref('admin_member_password_maps');
    my $address  = $optargs->{ address };
    my $password = $optargs->{ password };

    # simple sanity check: verify non empty input or not?
    unless ($address && $password) {
	return 0;
    }

    # get candidates
    my ($user, $domain) = split(/\@/, $address);

    for my $map (@$maplist) {
	use IO::Adapter;
	my $mapobj = new IO::Adapter $map;
	my $addrs  = $mapobj->find( $user , { want => 'key,value', all => 1 });

	# if this $map has this $user entry,
	# try to check { user => password } relation.
	if (defined $addrs) {
	  PASSWORD_ENTRY:
	    for my $r (@$addrs) {
		my ($u, $p_infile) = split(/\s+/, $r);
		my $p_input        = crypt( $password, $p_infile );

		# password match
		if ($p_infile eq $p_input) {
		    Log("check_password: password match");
		    return 1;
		}
            }
        }
    }

    LogWarn("check_password: password not match");
    return 0;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Command::Auth appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
