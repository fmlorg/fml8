#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: User.pm,v 1.3 2004/07/11 15:43:40 fukachan Exp $
#

package FML::Sys::User;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use Config;


=head1 NAME

FML::Sys::User - get user infomation on this system.

=head1 SYNOPSIS

=head1 DESCRIPTION

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
	    while ($buf = <$fh>) {
		($user) = split(/:/, $buf);
		$users->{ $user } = $user;
	    }

	    $fh->close();
	}
    }

    return $users;
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Sys::User appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
