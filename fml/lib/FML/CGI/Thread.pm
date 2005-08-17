#-*- perl -*-
#
#  Copyright (C) 2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Thread.pm,v 1.6 2005/08/17 10:33:16 fukachan Exp $
#

package FML::CGI::Thread;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::Thread - CGI details to control thread system

=head1 SYNOPSIS

    $obj = new FML::CGI::Thread;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Thread> is a subclass of C<FML::Process::CGI>.

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

=cut


# Descriptions: print out HTML header + body former part
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $name_ui   = $curproc->message_nl('term.thread_interface');
    my $title     = "${ml_name}\@${ml_domain} $name_ui";
    my $color     = $config->{ thread_cgi_bgcolor } || '#E6E6FA';
    my $charset   = $curproc->langinfo_get_charset("cgi");

    # o.k start html
    print start_html(-title   => $title,
		     -lang    => $charset,
		     -BGCOLOR => $color);
    print "\n";
}


# Descriptions: print out body latter part
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


# Descriptions: currently, dummy.
#               this routine is executed before table based navigation.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc) = @_;
    my $max_id    = $curproc->article_get_max_id();
    my $cur_id    = $curproc->safe_param_article_id() || 0;
    my $range     = $cur_id;
    my $th_args   = {
	last_id => $max_id,
    };

    if ($cur_id) {
	use FML::Article::Thread;
	my $article_thread = new FML::Article::Thread $curproc;
	$article_thread->set_print_style('html');

	# interpret subcommand e.g. "close" / "open".
	my $command = $curproc->safe_param_command() || '';
	if ($command eq 'close') {
	    $th_args->{ range } = $range || '';
	    $article_thread->close_thread_status($th_args);
	}
    }
}


# Descriptions: main routine for thread control.
#               this output is shown at table center.
#               run_cgi() can process request: list, show, change_status
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_menu
{
    my ($curproc)     = @_;
    my $myname        = $curproc->myname();
    my $ml_name       = $curproc->cgi_var_ml_name() || '';
    my $max_id        = $curproc->article_get_max_id();
    my $cur_id        = $curproc->safe_param_article_id();
    my $range         = $cur_id;
    my $default_range = 'last:10';
    my $th_args       = {
	last_id => $max_id,
    };

    # specified command, we need to identify
    # the command specifined in the cgi_navigation and cgi_mein.
    my $navi_command = $curproc->safe_param_navi_command() || '';
    my $command      = $curproc->safe_param_command()      || 'summary';

    print "<!-- exec run_cgi_menu start -->\n";

    unless ($ml_name) {
	print "<!-- ml_name unspecified, so show help and exit -->\n";
    }
    else {
	use FML::Article::Thread;
	my $article_thread = new FML::Article::Thread $curproc;
	$article_thread->set_print_style('html');

	# set print engine to my owe one.
	my $fp = \&__psw_message_queue_html_summary_print;
	$article_thread->set_print_function('summary', $fp);

	if ($command eq 'one_line_summary') {
	    $th_args->{ range } = $range || $default_range;
	    $article_thread->print_one_line_summary($th_args);
	}
	elsif ($command eq 'summary') {
	    $th_args->{ range } = $range || $default_range;
	    $article_thread->print_summary($th_args);
	}
	elsif ($command eq 'close' || $command eq 'open' ||
	       $command eq 'reopen' ) {
	    $th_args->{ range } = $default_range;
	    $article_thread->print_summary($th_args);
	}
	elsif ($command eq 'list') {
	    $th_args->{ range } = $range || '';
	    $article_thread->print_list($th_args);
	    # $article_thread->print_one_line_summary($th_args);
	}
	else {
	    my $r = "unknown subcommand: thread $command";
	    $curproc->logerror($r);
	    $curproc->ui_message("error: $r");
	}
    }

    print "<!-- exec run_cgi_menu end -->\n";
}


# Descriptions: print navigation bar
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $action    = $curproc->cgi_var_action();
    my $target    = $curproc->cgi_var_frame_target();
    my $ml_list   = $curproc->cgi_var_ml_name_list();
    my $ml_name   = $curproc->cgi_var_ml_name();

    # natural language-ed name
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_change  = $curproc->message_nl('term.change',  'change');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');

    print start_form(-action=>$action, -target=>$target);
    print $curproc->cgi_hidden_info_language();
    print $name_ml_name, ":\n";
    print popup_menu(-name   => 'ml_name', -values => $ml_list);
    print "<BR>\n";

    if (0) {
	print "orderd by: ";
	my $order = [ 'cost', 'date', 'reverse date' ];
	print popup_menu(-name   => 'order', -values => $order );
	print "<BR>\n";
    }

    # 3. submit
    print submit(-name => $name_change);
    print reset(-name  => $name_reset);

    print end_form;
    print "<HR>\n";
}


# Descriptions: show help
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_help
{
    my ($curproc) = @_;
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $mode      = $curproc->cgi_var_cgi_mode();
    my $role      = $curproc->message_nl('term.thread_interface');
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

command_help.

=cut


# Descriptions: show thread command dependent help.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_command_help
{
    my ($curproc)    = @_;
    my $buf          = '';
    my $navi_command = $curproc->safe_param_navi_command() || '';
    my $command      = $curproc->safe_param_command() || 'summary';
    my $msg_args     = $curproc->_gen_msg_args();

    # re-define: open|close -> summary.
    if ($command =~ /close|open/) { $command = 'summary';}

    # natural language-ed name
    my $name_usage   = $curproc->message_nl('term.usage',  'usage');

    if ($navi_command) {
	print "[$name_usage]<br> <b> $navi_command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.thread.$navi_command", '', $msg_args);
    }
    elsif ($command) {
	print "[$name_usage]<br> <b> $command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.thread.$command", '', $msg_args);
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



#
# THIS MODULE SPECIFIC METHODS
#


# Descriptions: print summary.
#               See templates within FML::Article::Thread class.
#    Arguments: OBJ($self) OBJ($curproc) ARRAY_REF($queue)
# Side Effects: none
# Return Value: none
sub __psw_message_queue_html_summary_print
{
    my ($self, $curproc, $queue) = @_;
    my $q       = $queue->[ 0 ] || {};
    my $wh      = $q->{ output_channel } || \*STDOUT;
    my $target  = $curproc->cgi_var_frame_target();
    my $action  = $curproc->cgi_var_action();
    my $ml_name = $curproc->cgi_var_ml_name();

    # debug
    print "debug: queue length = ", ($#$queue + 1), "\n";

    # terms
    my $term_article = $curproc->message_nl('term.article', 'article(s)');
    my $term_status  = $curproc->message_nl('term.status', 'status');
    my $term_change  = $curproc->message_nl('term.status_change',
					    'change status');
    my $term_summary = $curproc->message_nl('term.thread_summary',
					    'thread summary');

    print $wh "<table border=4>\n";
    print $wh "<td> $term_article </td>\n";
    print $wh "<td> $term_status  </td>\n";
    print $wh "<td> $term_change  </td>\n";
    print $wh "<td> $term_summary </td>\n";
    print $wh "</tr>\n";

    my $buf;
    for my $q (@$queue) {
	my $cur_id  = $q->{ cur_id }  || '';
	my $head_id = $q->{ head_id } || '';
	my $id_list = $q->{ id_list } || [];
	my $status  = $q->{ status }  || 'unknown';
	my $summary = $q->{ summary } || '';
	my $msg     = $q->{ message } || undef;
	my $wh      = $q->{ output_channel } || \*STDOUT;
	my $prompt  = "";

	print $wh "<!-- cur_id=$cur_id head_id=$head_id -->\n";
	print $wh "<tr>\n";

	if ($cur_id && $head_id) {
	    if ($head_id == $cur_id) {
		$buf  = start_form(-action=>$action, -target=>$target);
		$buf .= hidden(-name=>'article_id',-value=>$head_id,
			       -override=>1);
		$buf .= hidden(-name=>'ml_name',-value=>$ml_name,-override=>1);
		$buf .= hidden(-name=>'command',-value=>'close',-override=>1);
		$buf .= submit(-name => '-> close');

		print $wh "<td>\n @$id_list \n</td>\n";
		print $wh "<td>\n $status   \n</td>\n";
		print $wh "<td>\n $buf      \n</td>\n";
	    }
	    else {
		print $wh "<td> </td>\n";
		print $wh "<td> </td>\n";
		print $wh "<td> </td>\n";
	    }

	    print $wh "<td>\n";
	    $summary =~ s/^\s*/   /;
	    $summary =~ s/\n\s*/\n   /g;
	    print $wh $summary;

	    print $wh "</td>\n";
	}
	else {
	    carp("psw_message_queue_html_summary_print: invalid data");
	}

	print $wh "</tr>\n";
    }

    print $wh "</table>\n";
}


=head1 SEE ALSO

L<CGI>,
L<FML::Process::CGI>
and
L<FML::Process::Flow>

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
