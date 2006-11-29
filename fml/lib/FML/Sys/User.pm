#-*- perl -*-
#
#  Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: User.pm,v 1.6 2006/11/26 09:11:23 fukachan Exp $
#

package FML::Sys::User;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Config;


=head1 NAME

FML::Sys::User - get user information on this system.

=head1 SYNOPSIS

use FML::Sys::User;
my $sys  = new FML::Sys::User $curproc;
my $list = $sys->get_user_list();

=head1 DESCRIPTION

This module provides methods to handle user information on this system.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) OBJ($curproc)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $curproc) = @_;
    my ($type) = ref($self) || $self;
    my $me     = { _curproc => $curproc };
    return bless $me, $type;
}


=head2 get_user_list()

return user list as HASH_REF.

=cut


# Descriptions: return user list as HASH_REF.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub get_user_list
{
    my ($self) = @_;

    # XXX-TODO: how do we do on Windows NT ???
    return $self-> _get_user_list_on_unix();
}


# Descriptions: return user list as HASH_REF.
#               we assume all unix system has /etc/passwd.
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: HASH_REF
sub _get_user_list_on_unix
{
    my ($self) = @_;
    my $users  = {};

    if (-f "/etc/passwd") {
	use FileHandle;
	my $fh = new FileHandle "/etc/passwd";
	if (defined $fh) {
	    my ($user, $buf);
	  LINE:
	    while ($buf = <$fh>) {
		($user) = split(/:/, $buf);
		$users->{ $user } = $user;
	    }

	    $fh->close();
	}
    }

    return $users;
}


#
# DEBUG
#
if ($0 eq __FILE__) {
    my $sys  = new FML::Sys::User;
    my $list = $sys->get_user_list();

    my ($k, $v);
    for my $k (sort keys %$list) {
	printf "%-20s => %s\n", $k, $list->{ $k };
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004,2005,2006 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Sys::User appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
