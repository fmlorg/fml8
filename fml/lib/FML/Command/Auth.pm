#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Auth.pm,v 1.1 2002/03/22 15:30:45 fukachan Exp $
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

=head2 C<new()>

=cut


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


sub reject
{ 
    return 0;
}


sub check_password
{
    my ($self, $curproc, $args, $optargs) = @_; 
    my $config   = $curproc->{ config };
    my $maplist  = $config->get_as_array_ref('admin_member_passwd_maps');
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
	my $obj = new IO::Adapter $map;
	my $addrs = $obj->find( $user , { want => 'key,value', all => 1 });

	if (defined $addrs) {
	  LOOP:
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
