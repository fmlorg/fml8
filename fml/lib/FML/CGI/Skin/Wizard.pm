#-*- perl -*-
#
#  Copyright (C) 2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Menu.pm,v 1.12 2004/07/23 13:16:33 fukachan Exp $
#

package FML::CGI::Skin::Wizard;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::CGI::Skin::Base;
@ISA = qw(FML::CGI::Skin::Base);

my $debug = 0;


=head1 NAME

FML::CGI::Skin::Wizard - provides CGI control function for the specific domain.

=head1 SYNOPSIS

    $obj = new FML::CGI::Menu;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc) = @_;

    if ($curproc->is_valid_input()) {
	return $curproc->SUPER::run_cgi_navigator();
    }
    else {
	$curproc->cgi_var_navigator_title();

	# 1.1 menu description.
	my $desc  = $curproc->message_nl("cgi.wizard_navigation",
					 "1) select ml_name, 2) command\n");
	print $desc, "\n";
	print "\n<BR>\n";
    }
}


# Descriptions: show menu (old style, list based menu).
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_menu
{
    my ($curproc) = @_;
    my $target    = $curproc->cgi_var_frame_target();
    my $action    = $curproc->cgi_var_action();

    # natural language-ed name
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_switch  = $curproc->message_nl('term.switch',  'switch to');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');


    # 0. call command specific menu if both ml_name and command specified.
    if ($curproc->is_valid_input()) {
	return $curproc->cgi_execute_cgi_menu();
    }


    # 1. ML
    my $ml_name = $curproc->cgi_var_ml_name();
    my $ml_list = $curproc->cgi_var_ml_name_list();
    my $title   = $curproc->cgi_var_navigator_title();
    print $title, "\n";

    # 1.1 ML selection.
    print "<P>\n";
    if ($ml_name) {
	print "1. O.K. ml_name = $ml_name selected. <BR>\n";
    }
    else {
	my $size = $#$ml_list + 1;

	my $_desc = "1. select ml_name.\n";
	my $desc  = $curproc->message_nl("cgi.select_ml_name", $_desc);
	print $desc;
	print "<BR>\n";

	print start_form(-action=>$action, -target=>$target);
	print $name_ml_name, ":\n";
	print scrolling_list(-name    => 'ml_name',
			     -values  => $ml_list,
			     -default => [ $ml_name ],
			     -size    => $size > 5 ? 5 : $size);
	print "<BR>\n";
	print submit(-name => $name_switch);
	print reset(-name  => $name_reset);
	print end_form;

	return;
    }


    # 2. list up command.
    my $next_button = $curproc->message_nl("cgi.button_next", "next");
    print "<P>\n";
    print $curproc->message_nl("cgi.select_command", 
			       "2. select command.");
    print "\n<BR>\n";

    print "\n<UL>\n";
    my $navi_command    = $curproc->safe_param_navi_command() || '';
    my $command         = $curproc->safe_param_command() || '';
    my $command_default = $navi_command || $command;
    my $command_list    = $curproc->cgi_var_available_command_list();
    for my $command (@$command_list) {
	print "\n<LI>\n";
	print start_form(-action=>$action, -target=>$target);
	print $curproc->cgi_hidden_info_language();

	# command info
	my $name_command = $curproc->message_nl("cgi.select_$command",
						$command);
	print $name_command;
	print hidden(-name    => 'navi_command',
		     -default => [ $command ],
		     );
	print hidden(-name    => 'ml_name',
		     -default => [ $ml_name ],
		     );
	print submit(-name => $next_button);
	print "\n<BR>\n";

	print end_form;
    }
    print "\n</UL>\n";
}


# Descriptions: check whether enough data is input.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub is_valid_input
{
    my ($curproc) = @_;

    my $ml_name         = $curproc->cgi_var_ml_name();
    my $navi_command    = $curproc->safe_param_navi_command() || '';
    my $command         = $curproc->safe_param_command() || '';
    my $command_default = $navi_command || $command;
    if ($ml_name && $command_default) {
	return 1;
    }
    else {
	return 0;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Skin::Wizard first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
