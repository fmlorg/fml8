#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Menu.pm,v 1.11 2004/03/31 12:34:26 fukachan Exp $
#

package FML::CGI::Menu;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);

my $debug = 0;


=head1 NAME

FML::CGI::Menu - provides CGI control function for the specific domain.

=head1 SYNOPSIS

    $obj = new FML::CGI::Menu;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Menu> is a subclass of C<FML::Process::CGI>.

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
 FML::CGI::Menu

=head1 METHODS

Almost cgi common methods are forwarded to
C<FML::Process::CGI> base class.

This module has routines needed for the admin CGI.

=cut


# Descriptions: print out HTML header + body former part.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $myname    = $curproc->cgi_var_myname();
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $name_ui   = $curproc->message_nl('term.config_interface');
    my $title     = "${ml_name}\@${ml_domain} $name_ui";
    my $color     = $config->{ cgi_main_menu_color } || '#FFFFFF';
    my $charset   = $curproc->get_charset("cgi");

    # o.k start html
    print start_html(-title   => $title,
		     -lang    => $charset,
		     -BGCOLOR => $color);
    print "\n";
}


# Descriptions: print out body latter part.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub html_end
{
    my ($curproc) = @_;

    # o.k. end of html
    print end_html;
    print "\n";
}


# Descriptions: main routine for CGI.
#               kick off suitable FML::Command finally
#               via cgi_execulte_command().
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $address   = $curproc->cgi_try_get_address();
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $pcb       = $curproc->pcb();
    my $mode      = 'admin'; # cgi runs under admin mode (same way as makefml)

    # specified command, we need to identify
    # the command specifined in the cgi_navigation and cgi_mein.
    my $navi_command = $curproc->safe_param_navi_command() || '';
    my $command      = $curproc->safe_param_command()      || '';

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
	$curproc->cgi_execute_command($command_args);
    }
    elsif ($command && $address) {
	print "<br>* case 2 <br>\n" if $debug;

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
	$curproc->cgi_execute_command($command_args);
    }
    elsif ($navi_command) {
	print "<br>* case 3 <br>\n" if $debug;

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


# Descriptions: show menu (table based menu).
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc) = @_;
    my $target    = $curproc->cgi_var_frame_target();
    my $action    = $curproc->cgi_var_action();

    # natural language-ed name
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_change  = $curproc->message_nl('term.change',  'change');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');

    # 1. ML
    my $ml_name = $curproc->cgi_var_ml_name();
    my $ml_list = $curproc->cgi_var_ml_name_list();
    my $title   = $curproc->cgi_var_navigator_title();
    print $title, "\n";

    print start_form(-action=>$action, -target=>$target);
    print $curproc->cgi_hidden_info_language();

    print $name_ml_name, ":\n";
    print scrolling_list(-name    => 'ml_name',
			 -values  => $ml_list,
			 -default => [ $ml_name ],
			 -size    => 5);
    print "\n<BR>\n";

    # 2. command
    my $navi_command    = $curproc->safe_param_navi_command() || '';
    my $command         = $curproc->safe_param_command() || '';
    my $command_default = $navi_command || $command;
    my $command_list    = $curproc->cgi_var_available_command_list();

    print $name_command, ":\n";
    print scrolling_list(-name    => 'navi_command',
			 -values  => $command_list,
			 -default => [ $command_default ],
			 -size    => 5);
    print "\n<BR>\n";


    # 3. submit
    print submit(-name => $name_change);
    print reset(-name  => $name_reset);

    print end_form;
}


=head2 run_cgi_menu()

execute cgi_menu() given as FML::Command::*

=cut


# Descriptions: show meu.
#    Arguments: OBJ($curproc)
# Side Effects: load module
# Return Value: none
sub run_cgi_menu
{
    my ($curproc)    = @_;

    $curproc->cgi_execute_cgi_menu();
}


=head2 run_cgi_help()

show help.

=cut


# Descriptions: show help.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_help
{
    my ($curproc) = @_;
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $mode      = $curproc->cgi_var_cgi_mode();
    my $role      = $curproc->message_nl('term.config_interface');
    my $msg_args  = $curproc->_gen_msg_args();

    print "<B>\n<CENTER>\n";
    if ($mode eq 'admin') {
	print "fml CGI $role for \@$ml_domain ML's\n";
    }
    else {
	print "fml CGI $role for $ml_name\@$ml_domain ML\n";
    }
    print "</CENTER><BR>\n</B>\n";

    # top level help message
    my $buf  = '';
    if ($mode eq 'admin') {
	$buf = $curproc->message_nl("cgi.admin.top", "", $msg_args);
    }
    else {
	$buf = $curproc->message_nl("cgi.ml-admin.top", "", $msg_args);
    }

    print $buf;
}


=head2 run_cgi_command_help()

show command dependent help.

=cut


# Descriptions: show command dependent help.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_command_help
{
    my ($curproc)    = @_;
    my $buf          = '';
    my $navi_command = $curproc->safe_param_navi_command();
    my $command      = $curproc->safe_param_command();
    my $msg_args     = $curproc->_gen_msg_args();

    # natural language-ed name
    my $name_usage   = $curproc->message_nl('term.usage',  'usage');

    if ($navi_command) {
	print "[$name_usage]<br> <b> $navi_command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.config.$navi_command", '', $msg_args);
    }
    elsif ($command) {
	print "[$name_usage]<br> <b> $command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.config.$command", '', $msg_args);
    }

    print $buf;
}


# Descriptions: prepare arguemnts for message handling.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: HASH_REF
sub _gen_msg_args
{
    my ($curproc) = @_;

    # natural language-ed name
    my $name_submit = $curproc->message_nl('term.submit', 'submit');
    my $name_show   = $curproc->message_nl('term.show',   'show');
    my $name_map    = $curproc->message_nl('term.map',    'map');
    my $msg_args    = {
	_arg_button_submit => $name_submit,
	_arg_button_show   => $name_show,
	_arg_scroll_map    => $name_map,
    };

    return $msg_args;
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and
L<FML::Process::Flow>.

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

2003/09/25: FML::CGI::Menu is derived from FML::CGI::Admin::Menu.

FML::CGI::Menu first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
