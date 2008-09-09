#-*- perl -*-
#
#  Copyright (C) 2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: User.pm,v 1.16 2006/03/05 09:50:42 fukachan Exp $
#

package FML::CGI::User;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines


=head1 NAME

FML::CGI::User - manipulate user related operations for cgi scripts.

=head1 SYNOPSIS

    use FML::CGI::User;
    my $submit = new FML::CGI::User;
    $submit->cgi_menu($curproc, $command_context);

    use FML::CGI::User;
    my $submit = new FML::CGI::User;
    $submit->anonymous_cgi_menu($curproc, $command_context);

=head1 DESCRIPTION

The main purpose of CGI interface provides easy manipulation of users,
e.g. subscribe and unsubscribe.

FML::CGI::User class provides the entrance for such operations.

=head1 METHODS

=head2 new()

constructor.

=cut


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


=head1 METHODS for ADMINISTRATORS' CGI

=head2 cgi_menu($curproc, $command_context)

create a menu for the specified user related operation.

This method provides a menu for administrators.

=cut


# Descriptions: show menu for user control commands such as
#               subscribe, unsubscribe, addadmin, byeadmin, ...
#    Arguments: OBJ($self) OBJ($curproc) OBJ($command_context)
# Side Effects: none
# Return Value: none
sub cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $target       = $curproc->cgi_var_frame_target();
    my $action       = $curproc->cgi_var_action();
    my $ml_list      = $curproc->cgi_var_ml_name_list();
    my $address      = $curproc->safe_param_address() || '';
    my $ml_name      = $command_context->get_ml_name();
    my $comname      = $command_context->get_cooked_command();
    my $address_list = [];
    my $selected_key = '';

    #
    # XXX $comman_args are checked already.
    #     $command_context are passed in the following way:
    #       FML::CGI::Menu::run_cgi_main et.al. builds/checks $command_context.
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
	$address_list = $curproc->_get_address_list( 'recipient_maps' );
	$selected_key = 'recipients';
    }
    elsif (0) {
	$address_list = $curproc->_get_address_list( 'member_maps' );
	$selected_key = 'members';
    }
    # XXX digest operatoins is asymmetric with *_maps.
    elsif ($comname eq 'digestoff') {
	$address_list = $curproc->_get_address_list( 'digest_recipient_maps' );
	$selected_key = 'digest_recipients';
    }
    elsif ($comname eq 'addadmin' ||
	   $comname eq 'adminadd' ||
	   $comname eq 'admindel' ||
	   $comname eq 'deladmin' ||
	   $comname eq 'byeadmin'  ) {
	$address_list = $curproc->_get_address_list( 'admin_member_maps' );
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


# Descriptions: get address list for the specified map.
#    Arguments: OBJ($curproc) STR($map)
# Side Effects: none
# Return Value: ARRAY_REF
sub _get_address_list
{
    my ($curproc, $map) = @_;
    my $config = $curproc->config();
    my $list   = $config->get_as_array_ref( $map );

    use FML::User::Control;
    unless ($@) {
	my $obj = new FML::User::Control;
	return $obj->get_user_list($curproc, $list);
    }

    return [];
}


=head1 ANONYMOUS CGI

=head2 anonymous_cgi_menu($curproc, $command_context)

create a menu for the specified user related operation.

This method provides a menu for anonymous users.

=cut


# Descriptions: show the menu for anonymous user request.
#    Arguments: OBJ($self) OBJ($curproc) HASH_REF($command_context)
# Side Effects: none
# Return Value: none
sub anonymous_cgi_menu
{
    my ($self, $curproc, $command_context) = @_;
    my $target  = $curproc->cgi_var_frame_target();
    my $action  = $curproc->cgi_var_action();
    my $comname = $command_context->{ comname };

    use FML::CGI::Anonymous::DB;
    my $db = new FML::CGI::Anonymous::DB $curproc;
    my $session_id = $db->get_session_id();

    # natural language-ed name
    my $_mgs         = "magic string";
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_address = $curproc->message_nl('term.address', 'address');
    my $name_magic   = $curproc->message_nl('term.magic_string', $_mgs);
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_submit  = $curproc->message_nl('term.submit',  'submit');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');

    my $name_usage   = $curproc->message_nl("cgi.anonymous.$comname");
    print "<p>$name_usage\n";

    if ($comname eq 'subscribe' || $comname eq 'unsubscribe') {
	print start_form(-action=>$action, -target=>$target);

	print hidden(-name => 'session_id',   -default => [ $session_id ]);
	print hidden(-name => 'command',      -default => [ $comname ]);
	print hidden(-name => 'navi_command', -default => [ $comname ]);

	print "<!-- new line -->\n";
	print "<table border=0 cellspacing=\"0\" cellpadding=\"5\">\n";

	print "<!-- new line -->\n";
	print "<tr>\n";
	print "<td>\n";
	print $name_address;
	print "<td>\n";
	print textfield(-name  => 'address_specified',
			-size  => 30);

	print "<!-- new line -->\n";
	print "<tr>\n";
	print "<td>\n";
	print $name_magic;
	print "<td>\n";
	print textfield(-name  => 'magic_string',
			-size  => 30);

	print "<!-- new line -->\n";
	print "</table>\n";

	print "<br>\n";
	print submit(-name => $name_submit);
	print reset(-name  => $name_reset);
	print end_form();
    }
    elsif ($comname eq 'chaddr') {
	my $name_old_address = $curproc->message_nl('term.address_old', 
						    'old address');
	my $name_new_address = $curproc->message_nl('term.address_new', 
						    'new address');

	print start_form(-action=>$action, -target=>$target);

	print hidden(-name => 'session_id',   -default => [ $session_id ]);
	print hidden(-name => 'command',      -default => [ $comname ]);
	print hidden(-name => 'navi_command', -default => [ $comname ]);

	print "<!-- new line -->\n";
	print "<table border=0 cellspacing=\"0\" cellpadding=\"5\">\n";

	print "<!-- new line -->\n";
	print "<tr>\n";
	print "<td>\n";
	print $name_old_address;
	print "<td>\n";
	print textfield(-name  => 'old_address',
			-size  => 30);

	print "<!-- new line -->\n";
	print "<tr>\n";
	print "<td>\n";
	print $name_new_address;
	print "<td>\n";
	print textfield(-name  => 'new_address',
			-size  => 30);

	print "<!-- new line -->\n";
	print "<tr>\n";
	print "<td>\n";
	print $name_magic;
	print "<td>\n";
	print textfield(-name  => 'magic_string',
			-size  => 30);

	print "<!-- new line -->\n";
	print "</table>\n";

	print "<br>\n";
	print submit(-name => $name_submit);
	print reset(-name  => $name_reset);
	print end_form();
    }
    else {
	print "NOT SUPPORTED\n<br>\n";
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::User first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
