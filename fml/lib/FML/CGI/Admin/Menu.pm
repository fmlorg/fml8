#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Configure.pm,v 1.9 2001/12/23 11:39:44 fukachan Exp $
#

package FML::CGI::Admin::Menu;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Admin::Menu - provides functions for makefml CGI interface

=head1 SYNOPSIS

    $obj = new FML::CGI::Admin::Menu;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Admin::Menu> is a subclass of C<FML::Process::CGI>.

             FML::Process::Kernel
                       |
                       A
             FML::Process::CGI
                       |
                       A
            -----------------------
           |                       |
           A                       A
 FML::CGI::Admin::Menu

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for CGI.

=cut


# Descriptions: print out HTML header + body former part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $myname  = $curproc->myname();
    my $ml_name = $curproc->safe_param_ml_name();
    my $title   = "$ml_name configuration interface";
    my $color   = '#E6E6FA';
    my $charset = 'euc-jp';

    # o.k start html
    print start_html(-title=>$title,
		     -lang => $charset,
		     -BGCOLOR=>$color);
    print "\n";
}


# Descriptions: print out body latter part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_end
{
    my ($curproc, $args) = @_;

    # o.k. end of html
    print end_html;
    print "\n";
}


sub _try_get_address
{
    my ($curproc, $args) = @_;
    my $address = '';
    my $a = '';

    eval q{ $a = $curproc->safe_param_address_specified();};
    unless ($@) {
	$address = $a;
    }
    else {
	# XXX longjmp() if insecure input is given.
	my $r = $@;
	if ($r =~ /ERROR\.INSECURE/) { croak($r);}

	eval q{ $a = $curproc->safe_param_address_selected();};
	unless ($@) {
	    $address = $a;
	}
	else {
	    # XXX longjmp() if insecure input is given.
	    my $r = $@;
	    if ($r =~ /ERROR\.INSECURE/) { croak($r);}
	}
    }

    return $address;
}



# Descriptions: show help
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_help
{
    my ($curproc, $args) = @_;
    my $domain = $curproc->default_domain();

    print "<B>\n";
    print "fml CGI interface for \@$domain ML's\n";
    print "</B>\n";
}


# Descriptions: main routine for makefml.cgi.
#               kick off suitable FML::Command finally via _execulte_command().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc, $args) = @_;
    my $command = $curproc->safe_param_command() || '';
    my $address = $curproc->_try_get_address($args);

    if ($command && $address) {
	my $ml_name      = $curproc->safe_param_ml_name();
	my $command_args = {
	    command_mode => 'admin',
	    comname      => $command,
	    command      => $command,
	    ml_name	 => $ml_name,
	    options      => [ $address ],
	    argv         => undef,
	    args         => undef,
	};
	$curproc->_execute_command($args, $command_args);

	print hr;
	$curproc->_show_menu($args);
    }
    else {
	my $ml_name = $curproc->safe_param_ml_name();

	if ($ml_name) {
	    $curproc->_show_menu($args);
	}
	else {
	    $curproc->run_cgi_help($args);
	}
    }
}


# Descriptions: execute FML::Command
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: load module
# Return Value: none
sub _execute_command
{
    my ($curproc, $args, $command_args) = @_;

    use FML::Command;
    my $obj = new FML::Command;
    if (defined $obj) {
	my $comname = $command_args->{ comname };
	eval q{
	    $obj->$comname($curproc, $command_args);
	};
	unless ($@) {
	    print "OK! $comname succeed.\n";
	}
	else {
	    print "Error! $comname fails.\n<BR>\n";
	    if ($@ =~ /^(.*)\s+at\s+/) {
		my $reason = $@;
		print "<BR>\n";
		print $1;
		print "<BR>\n";
		print $reason;
		print "<BR>\n";
	    }
	}
    }
}


# Descriptions: show menu
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _show_menu
{
    my ($curproc, $args) = @_;
    my $action  = $curproc->myname();
    my $target  = '_top';
    my $ml_list = $curproc->get_ml_list($args);
    my $address = $curproc->safe_param_address() || '';
    my $config  = $curproc->{ config };

    # 
    my $address_list = $curproc->get_recipient_list();
    my $command_list = 
	$config->get_as_array_ref('available_commands_for_admin_cgi');


    print start_form(-action=>$action, -target=>$target);

    print table( { -border => undef },
		Tr( undef, 
		   td([
		       "ML: ",
		      popup_menu(-name => 'ml_name', -values => $ml_list)
		      ])
		   ),
		Tr( undef, 
		   td([
		       "command: ",
		       popup_menu(-name => 'command', -values => $command_list)
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
		       popup_menu(-name   => 'address_selected', 
				  -values => $address_list)
		       ]),
		   )
		);


    print submit(-name => 'submit');
    print reset(-name  => 'reset');
    print end_form;
}


# Descriptions: show menu
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc, $args) = @_;
    my $action  = $curproc->myname();
    my $target  = '_top';
    my $ml_list = $curproc->get_ml_list($args);
    my $address = $curproc->safe_param_address() || '';
    my $config  = $curproc->{ config };
    my $command_list = 
	$config->get_as_array_ref('available_commands_for_admin_cgi');

    # main menu
    {
	my $ml_name = $curproc->safe_param_ml_name() || '?';
	print "<B>fml admin menu</B>\n<BR>\n";
	print "ML: $ml_name\n<BR>\n";
    }

    print start_form(-action=>$action, -target=>$target);

    print "Go to: <BR>\n";
    print popup_menu(-name => 'ml_name', -values => $ml_list);
    print "\n<BR>\n";

    print submit(-name => 'change');
    print reset(-name  => 'reset');

    print end_form;
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and
L<FML::Process::Flow>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Admin::Menu appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
