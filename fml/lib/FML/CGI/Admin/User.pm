#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: User.pm,v 1.10 2002/07/02 03:55:21 fukachan Exp $
#

package FML::CGI::Admin::User;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines


# Descriptions: standard constructor
#    Arguments: OBJ($self)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


# Descriptions: show menu for user control commands such as
#               subscribe, unsubscribe, addadmin, byeadmin, ...
#    Arguments: OBJ($self)
#               OBJ($curproc)
#               HASH_REF($args)
#               HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $args, $command_args) = @_;
    my $action       = $curproc->myname();
    my $target       = '_top';
    my $ml_list      = $curproc->get_ml_list($args);
    my $address      = $curproc->safe_param_address() || '';
    my $config       = $curproc->{ config };
    my $ml_name      = $command_args->{ ml_name };
    my $comname      = $command_args->{ comname };
    my $address_list = [];

    # which address list to show at the scrolling list
    if ($comname eq 'subscribe'   || 
	$comname eq 'adduser'     ||
	$comname eq 'useradd'     ||
	$comname eq 'unsubscribe' ||
	$comname eq 'userdel'     ||
	$comname eq 'deluser'     ) {
	$address_list = $curproc->get_address_list( 'member_maps' );
    }
    elsif ($comname eq 'addadmin' ||
	   $comname eq 'adminadd' ||
	   $comname eq 'admindel' ||
	   $comname eq 'deladmin' ||
	   $comname eq 'byeadmin'  ) {
	$address_list = $curproc->get_address_list( 'admin_member_maps' );
    }

    # create <FORM ... > ... by (start_form() ... end_form())
    print start_form(-action=>$action, -target=>$target);

    print table( { -border => undef },
		Tr( undef,
		   td([
		       "ML: ",
		       textfield(-name    => 'ml_name',
				 -default => $ml_name,
				 -size    => 32)
		       ])
		   ),
		Tr( undef,
		   td([
		       "command: ",
		       textfield(-name    => 'command',
				 -default => $comname,
				 -size    => 32)
		       ])
		   ),
		Tr( undef,
		   td([
		       "address: ",
		       textfield(-name      => 'address_specified',
				 -default   => $address,
				 -override  => 1,
				 -size      => 32,
				 -maxlength => 64,
				 )
		       ])
		   ),
		Tr( undef,
		   td([
		       "",
		       scrolling_list(-name   => 'address_selected',
				      -values => $address_list,
				      -size   => 5)
		       ]),
		   )
		);


    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print end_form;
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Admin::User appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
