#-*- perl -*-
#
#  Copyright (C) 2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Menu.pm,v 1.20 2002/07/02 12:00:03 fukachan Exp $
#

package FML::CGI::Admin::Menu;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);

my $debug = 0;


=head1 NAME

FML::CGI::Admin::Menu - provides CGI controll for the specific domain

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
             FML::Process::CGI::Kernel
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

This module has routines needed for the admin CGI.

=cut


# Descriptions: print out HTML header + body former part
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $myname  = $curproc->myname();
    my $domain  = $curproc->ml_domain();
    my $ml_name = $curproc->cgi_try_get_ml_name($args);
    my $title   = "${ml_name}\@${domain} configuration interface";
    my $color   = $config->{ cgi_main_menu_color } || '#FFFFFF';
    my $charset = $config->{ cgi_charset } || 'euc-jp';

    # o.k start html
    print start_html(-title   => $title,
		     -lang    => $charset,
		     -BGCOLOR => $color);
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


# Descriptions: main routine for CGI.
#               kick off suitable FML::Command finally
#               via cgi_execulte_command().
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $address = $curproc->cgi_try_get_address($args);
    my $ml_name = $curproc->cgi_try_get_ml_name($args);
    my $hints   = $curproc->hints();
    my $pcb     = $curproc->{ pcb };
    my $mode    = 'admin'; # cgi runs under admin mode (same way as makefml)

    # specified command, we need to identify
    # the command specifined in the cgi_navigation and cgi_mein.
    my $navi_command = $curproc->safe_param_navi_command() || '';
    my $command      = $curproc->safe_param_command() || '';

    # updat config: $ml_name is found now (get $ml_name from CGI).
    $config->set('ml_name', $ml_name);

    if ($debug) {
	print "<PRE>\n";
	print "ml_name      = $ml_name\n";
	print "command      = $command\n";
	print "navi_command = $navi_command\n";
	print "</PRE>\n";
    }

    if (($command eq 'newml' && $ml_name) ||
	($command eq 'rmml'  && $ml_name)) {
	print "<br>* case 1 <br>\n" if $debug;
	my $command_args = {
	    command_mode => $mode,
	    comname      => $command,
	    command      => $command,
	    ml_name	 => $ml_name,
	    options      => [ ],
	    argv         => undef,
	    args         => undef,
	};

	$pcb->set('cgi', 'command_args', $command_args);
	$curproc->cgi_execute_command($args, $command_args);
    }
    elsif ($command && $address) {
	print "<br>* case 2 <br>\n" if $debug;
	my $ml_name      = $curproc->safe_param_ml_name();
	my $command_args = {
	    command_mode => $mode,
	    comname      => $command,
	    command      => $command,
	    ml_name	 => $ml_name,
	    options      => [ $address ],
	    argv         => undef,
	    args         => undef,
	};

	$pcb->set('cgi', 'command_args', $command_args);
	$curproc->cgi_execute_command($args, $command_args);
    }
    elsif ($navi_command) {
	print "<br>* case 3 <br>\n" if $debug;

	my $ml_name      = $curproc->safe_param_ml_name();
	my $command_args = {
	    command_mode => $mode,
	    comname      => $navi_command,
	    command      => $navi_command,
	    ml_name	 => $ml_name,
	    options      => [ ],
	    argv         => undef,
	    args         => undef,
	};

	$pcb->set('cgi', 'command_args', $command_args);
    }
    elsif ($command) {
	print "<br>* case 4 <br>\n" if $debug;

	my $ml_name      = $curproc->safe_param_ml_name();
	my $command_args = {
	    command_mode => $mode,
	    comname      => $command,
	    command      => $command,
	    ml_name	 => $ml_name,
	    options      => [ ],
	    argv         => undef,
	    args         => undef,
	};

	$pcb->set('cgi', 'command_args', $command_args);
    }
    else {
	print "<br>* case 5 <br>\n" if $debug;

	$pcb->set('cgi', 'command_args', undef);
    }
}


# Descriptions: show menu (table based menu)
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $action  = $curproc->myname();
    my $target  = '_top';

    # 1. ML
    my $ml_name = $curproc->cgi_try_get_ml_name($args);
    my $ml_list = $curproc->get_ml_list($args);
    my $fml_url = '<A HREF="http://www.fml.org/software/fml-devel/">fml</A>';
    print "<B>$fml_url admin menu</B>\n<BR>\n";

    print start_form(-action=>$action, -target=>$target);

    print "mailing list:\n";
    print scrolling_list(-name    => 'ml_name',
			 -values  => $ml_list,
			 -default => [ $ml_name ],
			 -size    => 5);
    print "\n<BR>\n";

    # 2. command
    my $navi_command    = $curproc->safe_param_navi_command() || '';
    my $command         = $curproc->safe_param_command() || '';
    my $command_default = $navi_command || $command;
    my $command_list    =
	$config->get_as_array_ref('commands_for_admin_cgi');

    print "  command:\n";
    print scrolling_list(-name    => 'navi_command',
			 -values  => $command_list,
			 -default => [ $command_default ],
			 -size    => 5);
    print "\n<BR>\n";


    # 3. submit
    print submit(-name => 'submit');
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

Copyright (C) 2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Admin::Menu first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
