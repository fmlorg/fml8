#-*- perl -*-
#
#  Copyright (C) 2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
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
    my $config  = $curproc->config();
    my $title   = $config->{ thread_cgi_title }   || 'thread system interface';
    my $color   = $config->{ thread_cgi_bgcolor } || '#E6E6FA';
    my $myname  = $curproc->myname();
    my $charset = $curproc->get_charset("cgi");

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
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_main
{
    my ($curproc) = @_;
}


# Descriptions: main routine for thread control.
#               run_cgi() can process request: list, show, change_status
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_menu
{
    my ($curproc)     = @_;
    my $myname        = $curproc->myname();
    my $ml_name       = $curproc->cgi_var_ml_name();
    my $command       = $curproc->cgi_var_action() || 'summary';
    my $max_id        = $curproc->article_max_id();
    my $cur_id        = $curproc->safe_param_article_id();
    my $range         = $cur_id;
    my $default_range = 'last:10';
    my $th_args       = {
	last_id => $max_id,
    };

    print "<!-- exec run_cgi_menu start -->\n";

    use FML::Article::Thread;
    my $article_thread = new FML::Article::Thread $curproc;
    $article_thread->set_print_style('html');

    if ($command eq 'one_line_summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'summary') {
	$th_args->{ range } = $range || $default_range;
	$article_thread->print_summary($th_args);
    }
    elsif ($command eq 'list') {
	$th_args->{ range } = $range || '';
	$article_thread->print_list($th_args);
	# $article_thread->print_one_line_summary($th_args);
    }
    elsif ($command eq 'open' || $command eq 'reopen') {
	$th_args->{ range } = $range || '';
	$article_thread->open_thread_status($th_args);
    }
    elsif ($command eq 'close') {
	$th_args->{ range } = $range || '';
	$article_thread->close_thread_status($th_args);
    }
    else {
	my $r = "unknown subcommand: thread $command";
	$curproc->logerror($r);
	$curproc->ui_message("error: $r");
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


sub run_cgi_help
{
    print "thread.cgi help\n";
}


sub run_cgi_command_help
{
    print "thread.cgi command help\n";
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

Copyright (C) 2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Thread first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
