#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: ThreadTrack.pm,v 1.12 2001/12/22 09:21:02 fukachan Exp $
#

package FML::CGI::ThreadTrack;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use CGI qw/:standard/; # load standard CGI routines
use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);


=head1 NAME

FML::CGI::ThreadTrack - CGI details to control thread system

=head1 SYNOPSIS

    $obj = new FML::CGI::ThreadTrack;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::ThreadTrack> is a subclass of C<FML::Process::CGI>.

=head1 METHODS

Almost methods common for CGI or HTML are forwarded to
C<FML::Process::CGI> base class.

=cut


# Descriptions: print out HTML header + body former part 
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_start
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $title   = $config->{ thread_cgi_title }   || 'thread system interface';
    my $color   = $config->{ thread_cgi_bgcolor } || '#E6E6FA';
    my $myname  = $curproc->myname();
    my $charset = $config->{ cgi_charset } || 'euc-jp';

    # o.k start html
    print start_html(-title=>$title,
		     -lang => $charset,
		     -BGCOLOR=>$color);
    print "\n";

    $curproc->_show_guide($args);
}


# Descriptions: print out body latter part 
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub html_end
{
    my ($curproc, $args) = @_;

    print "<HR>\n";
    $curproc->_show_guide($args);

    # o.k. end of html
    print end_html;
    print "\n";
}


# Descriptions: main routine for thread control
#               run_cgi() can process request: list, show, change_status
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $config->{ program_name };
    my $ttargs = $curproc->_build_param($args);
    my $action = $curproc->safe_param_action() || '';

    use Mail::ThreadTrack;
    my $thread = new Mail::ThreadTrack $ttargs;
    $thread->set_mode('html');

    if ($action eq 'list') {
	$thread->summary();
    }
    elsif ($action eq 'show') {
	my $id = $curproc->safe_param_article_id();
	my $tid = $thread->_create_thread_id_strings($id);
	$thread->show($tid);
    }
    elsif ($action eq 'change_status') {
	# fmlthread.cgi is for administorator, so you can change status.
	if ($myname eq 'fmlthread.cgi') {
	    my $list = $curproc->safe_paramlist2_threadcgi_change_status();
	    for my $param (@$list) {
		my ($ml, $id, $value) = @$param;
		if ($value eq 'closed') {
		    my $tid = $thread->_create_thread_id_strings($id);
		    print "closed $tid", br, "\n";
		    $thread->close($tid);
		}
	    }
	}
	else {
	    print "Warning: only administrator change status\n";
	}

	$thread->summary();
    }
    else {
	$thread->summary();
    }
}


# Descriptions: prepare basic parameter for Mail::ThreadTrack module
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: HASH_REF
sub _build_param
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $myname = $config->{ program_name };
    my $option = $curproc->command_line_options();

    #  argumente for thread track module
    my $ml_name       = $curproc->safe_param_ml_name();
    my $thread_db_dir = $config->{ thread_db_dir };
    my $spool_dir     = $config->{ spool_dir };
    my $max_id        = $curproc->article_id_max();
    my $ttargs        = {
	myname        => $myname,
	logfp         => \&Log,
	fd            => \*STDOUT,
	db_base_dir   => $thread_db_dir,
	ml_name       => $ml_name,
	spool_dir     => $spool_dir,
	reverse_order => 0,
    };

    # import some variables
    for my $varname (qw(base_url msg_base_url)) {
	if (defined $option->{ $varname }) {
	    $ttargs->{ $varname } = $option->{ $varname };
	}
	elsif (defined $config->{ $varname }) {
	    $ttargs->{ $varname } = $config->{ $varname };
	}
    }

    return $ttargs;
}


# Descriptions: print navigation bar
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _show_guide
{
    my ($curproc, $args) = @_;
    my $config  = $curproc->{ config };
    my $action  = $curproc->myname();
    my $target  = $config->{ thread_cgi_target_window } || '_top';
    my $ml_list = $curproc->get_ml_list($args);
    my $ml_name = $config->{  ml_name };

    print start_form(-action=>$action, -target=>$target);

    print "ML: ";
    print popup_menu(-name   => 'ml_name', -values => $ml_list);

    print "orderd by: ";
    my $order = [ 'cost', 'date', 'reverse date' ];
    print popup_menu(-name   => 'order', -values => $order );

    print submit(-name => 'change target');
    print reset(-name => 'reset');

    print end_form;
    print "<HR>\n";
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

FML::CGI::ThreadTrack appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
