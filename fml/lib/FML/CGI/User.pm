#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: User.pm,v 1.10 2004/07/23 13:16:33 fukachan Exp $
#

package FML::CGI::User;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines


# Descriptions: constructor.
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
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_args)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_args) = @_;
    my $target       = $curproc->cgi_var_frame_target();
    my $action       = $curproc->cgi_var_action();
    my $ml_list      = $curproc->cgi_var_ml_name_list();
    my $address      = $curproc->safe_param_address() || '';
    my $ml_name      = $command_args->{ ml_name };
    my $comname      = $command_args->{ comname };
    my $address_list = [];
    my $selected_key = '';

    #
    # XXX $comman_args are checked already.
    #     $command_args are passed in the following way:
    #       FML::CGI::Menu::run_cgi_main et.al. builds/checks $command_args.
    #       FML::CGI::Menu -(via PCB)-> cgi_execute_cgi_menu() -> cgi_menu().
    #

    # XXX-TODO: commnd list shoul be configurable by config files.
    # which address list to show at the scrolling list.
    if ($comname eq 'subscribe'   ||
	$comname eq 'adduser'     ||
	$comname eq 'useradd'     ||
	$comname eq 'unsubscribe' ||
	$comname eq 'userdel'     ||
	$comname eq 'deluser'     ||
	$comname eq 'digeston') {
	$address_list = $curproc->get_address_list( 'recipient_maps' );
	$selected_key = 'recipients';
    }
    elsif (0) {
	$address_list = $curproc->get_address_list( 'member_maps' );
	$selected_key = 'members';
    }
    # XXX digest operatoins is asymmetric with *_maps.
    elsif ($comname eq 'digestoff') {
	$address_list = $curproc->get_address_list( 'digest_recipient_maps' );
	$selected_key = 'digest_recipients';
    }
    elsif ($comname eq 'addadmin' ||
	   $comname eq 'adminadd' ||
	   $comname eq 'admindel' ||
	   $comname eq 'deladmin' ||
	   $comname eq 'byeadmin'  ) {
	$address_list = $curproc->get_address_list( 'admin_member_maps' );
	$selected_key = 'admin_members';
    }
    else {
	# XXX-TODO: nl ?
	croak("not allowed command");
    }

    # natural language-ed name
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_submit  = $curproc->message_nl('term.submit',  'submit');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');

    # create <FORM ... > ... by (start_form() ... end_form())
    print start_form(-action=>$action, -target=>$target);
    print $curproc->cgi_hidden_info_language();

    print table( { -border => undef },
		Tr( undef,
		   td([
		       $name_ml_name,
		       textfield(-name    => 'ml_name',
				 -default => $ml_name,
				 -size    => 32)
		       ])
		   ),
		Tr( undef,
		   td([
		       $name_command,
		       textfield(-name    => 'command',
				 -default => $comname,
				 -size    => 32)
		       ])
		   ),
		Tr( undef,
		   td([
		       "specify address: ",
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
		       "select address<br>($selected_key)",
		       scrolling_list(-name   => 'address_selected',
				      -values => $address_list,
				      -size   => 5)
		       ]),
		   )
		);


    print submit(-name => $name_submit);
    print reset(-name  => $name_reset);
    print end_form;
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

FML::CGI::User first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
