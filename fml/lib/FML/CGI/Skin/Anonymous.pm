#-*- perl -*-
#
#  Copyright (C) 2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Anonymous.pm,v 1.1 2008/09/09 08:48:59 fukachan Exp $
#

package FML::CGI::Skin::Anonymous;
use strict;
use Carp;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD $global_error_reason);
use CGI qw/:standard/; # load standard CGI routines

use FML::Process::CGI;
@ISA = qw(FML::Process::CGI);

my $debug = 0;


=head1 NAME

FML::CGI::Skin::Anonymous - provides CGI control function for anonymous users.

=head1 SYNOPSIS

    $obj = new FML::CGI::Skin::Anonymous;
    $obj->prepare();
    $obj->verify_request();
    $obj->run();
    $obj->finish();

run() executes html_start(), run_cgi() and html_end() described below.

See L<FML::Process::Flow> for flow details.

=head1 DESCRIPTION

=head2 CLASS HIERARCHY

C<FML::CGI::Skin::Anonymous> is a subclass of C<FML::Process::CGI>.

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
 FML::CGI::Skin::Anonymous

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
    my $name_ui   = $curproc->message_nl('cgi.anonymous.top');
    my $title     = "${ml_name}\@${ml_domain} $name_ui";
    my $color     = $config->{ cgi_main_menu_color } || '#FFFFFF';
    my $charset   = $curproc->langinfo_get_charset("cgi");

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
    my $mode      = 'anonymous'; # cgi needs to run for an anonymous user.

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

    # [I] 1st challenge phase ($curproc->prepare() has done it already).
    # 1.  save request and information before verification.
    # 1.1 assign a hidden id for this request.
    # 1.2 generate a challenge magic string (ALPHABET+, up to 8 chars).
    # 1.3 save them and the request into the temporal database.
    #     bind the challenge password with the id
    #     for the later reverse operation.
    #
    # 2.  show menu by $curproc->run_cgi_menu() at the center of table.
    #
    # [II] 2nd challenge phase: something is requested by an anonymou user.
    # 3.  check if this request is from a human or a spam robot ?
    # 3.1 use the challenge password (assigned at 1.2 above).
    my $is_ok = $curproc->_anonymous_is_human_operating();
    if ($is_ok) {
	# if confirmed that a human seems operating, process the request.
	$curproc->_anonymous_run_cgi_main();
    }
    else {
	if (defined $global_error_reason && $global_error_reason) {
	    my $buf = $curproc->message_nl("cgi.fail",
					   "Error! request fails.");
	    print "<p>", $buf, "<br>\n";
	}

	$curproc->logdebug("first time");
    }
}


# Descriptions: check if the request is operated by a human.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _anonymous_is_human_operating
{
    my ($curproc) = @_;

    if ($curproc->_anonymous_cgi_is_first_time()) {
	return 0;
    }
    else {
	my $session_id   = $curproc->safe_param_session_id();
	my $magic_string = $curproc->safe_param_magic_string();
	if ($session_id && $magic_string) {
	    $curproc->log("session_id = $session_id");
	    $curproc->logdebug("magic_string = $magic_string");
	}
	else {
	    $curproc->logwarn("invalid request");
	    return 0;
	}

	# check the magic string is valid or not. return 1 if ok.
	use FML::CGI::Anonymous::DB;
	my $db = new FML::CGI::Anonymous::DB $curproc;

	# 1. expired ?
	if ($db->is_expired($session_id)) {
	    $curproc->logerror("expired request");
	    $global_error_reason = "expired";
	    return 0;
	}

	# 2. not expired, ok, check if the magic string is correct.
	if ($db->is_correct_magic_string($session_id, $magic_string)) {
	    $curproc->log("correct magic string");
	    return 1;
	}
	else {
	    $global_error_reason = "incorrect_magic_string";
	    $curproc->logwarn("incorrect magic string");
	    return 0;
	}
    }
}


# Descriptions: main routine for CGI.
#               kick off suitable FML::Command finally
#               via cgi_execulte_command().
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _anonymous_run_cgi_main
{
    my ($curproc) = @_;
    my $config    = $curproc->config();
    my $pcb       = $curproc->pcb();
    my $mode      = 'user';

    my $ml_name      = $curproc->cgi_var_ml_name();
    my $address      = $curproc->cgi_try_get_address();
    my $navi_command = $curproc->safe_param_navi_command() || '';
    my $command      = $curproc->safe_param_command()      || '';

    # updat config: $ml_name is found now (get $ml_name from CGI).
    $config->set('ml_name', $ml_name);

    if ($debug) {
	print "<PRE>\n";
	print "ml_name      = $ml_name\n";
	print "command      = $command\n";
	print "navi_command = $navi_command\n";
	print "address      = $address\n";
	print "</PRE>\n";
    }

    if ($command && $address) {
	print "<br>* case 2 <br>\n" if $debug;

	my $command_context = 
	    $curproc->command_context_init($command);
	$command_context->set_mode("User");
	$command_context->set_ml_name($ml_name);
	$command_context->set_data($address);
	$command_context->set_options( [ $address ] );

	# XXX we need a fake that we handle a mail request.
	my $cred = $curproc->credential();
	$cred->set_sender($address);
	$curproc->set_allow_reply_message();

	$pcb->set('cgi', 'command_context', $command_context);
	$curproc->cgi_execute_command($command_context, "ml_anonymous_cgi");
    }
    else {
	$curproc->log("cgi_main: invalid condition, not processed.");
	$pcb->set('cgi', 'command_context', undef);
    }
}


# Descriptions: show menu (table based menu).
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_navigator
{
    my ($curproc, $args) = @_;
    my $target           = $curproc->cgi_var_frame_target();
    my $action           = $curproc->cgi_var_action();

    # natural language-ed name
    my $name_ml_name = $curproc->message_nl('term.ml_name', 'ml_name');
    my $name_command = $curproc->message_nl('term.command', 'command');
    my $name_submit  = $curproc->message_nl('term.submit',  'submit');
    my $name_reset   = $curproc->message_nl('term.reset',   'reset');

    # 1. ML
    # my $title   = $curproc->cgi_var_navigator_title();
    # print $title, "\n";

    # 2. command
    my $usage      = "anonymous usage";
    my $name_usage = $curproc->message_nl('cgi.anonymous.usage', $usage);
    print $name_usage;
    print "\n<BR>\n";

    # 3. submit
    # print submit(-name => $name_submit);
    # print reset(-name  => $name_reset);
}


=head2 run_cgi_menu()

execute cgi_menu() given as FML::Command::* class.
The menu function should be within FML::Command::User::* class.

    for my $command ($commands_for_ml_anonymous_cgi) {
        if $command in $anonymous_cgi_allowed_commands {
           FML::Command::User::$command->cgi_menu();
        }
    }

=cut


# Descriptions: show the main menu at the screen center.
#    Arguments: OBJ($curproc)
# Side Effects: load module
# Return Value: none
sub run_cgi_menu
{
    my ($curproc) = @_;
    my $msg_args  = $curproc->_gen_msg_args();

    # top level help message
    print $curproc->message_nl("cgi.anonymous.top", "", $msg_args);

    if ($curproc->_anonymous_cgi_is_first_time()) {
	$curproc->_anonymous_cgi_print_menu();
	$curproc->_anonymous_cgi_print_magic_string();
    }
    else {
	;
    }
}


# Descriptions: check if this request is done at the first time.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _anonymous_cgi_is_first_time
{
    my ($curproc) = @_;

    my $session_id = $curproc->safe_param_session_id();
    return( $session_id ? 0 : 1 );
}


# Descriptions: show menu for an anonymous user.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _anonymous_cgi_print_menu
{
    my ($curproc) = @_;
    my $ml_name   = $curproc->cgi_var_ml_name();

    for my $command (qw(subscribe unsubscribe)) {
	my $pkg = sprintf("FML::Command::User::%s", $command);
	my $command_context = {
	    command_mode => "user",
	    comname      => $command,
	    command      => $command,
	    ml_name	 => $ml_name,
	    options      => [ ],
	    argv         => undef,
	    args         => undef,
	};

	my $eval = qq{
	    use $pkg;
	    my \$command = new $pkg;
	    \$command->cgi_menu(\$curproc, \$command_context);
	};
	eval $eval;
	if ($@) {
	    print "$command not suport anonymous mode\n<br>\n";
	    print "{$@}\n";
	}
    }
}


# Descriptions: print the magic string.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _anonymous_cgi_print_magic_string
{
    my ($curproc)    = @_;
    my $config       = $curproc->config();
    my $_mgs         = "magic string";
    my $name_magic   = $curproc->message_nl('term.magic_string', $_mgs);
    my $is_mode      = "png";

    use FML::CGI::Anonymous::DB;
    my $db = new FML::CGI::Anonymous::DB $curproc;
    my $string       = $db->get_magic_string();
    my $session_id   = $db->get_session_id();

    use FML::String::Banner;
    my $banner = new FML::String::Banner $curproc;
    $banner->set_string($string);

    # firstly, check if image generator works.
    my $png = $banner->as_png();
    unless (defined $png) { $is_mode = "ascii";};

    # go! go! go!
    if ($is_mode eq "ascii") {
	my $ascii = $banner->as_ascii();
	printf("\n<p>[%s]\n<pre>\n%s\n</pre>\n", $name_magic, $ascii);
    }
    elsif ($is_mode eq "png") {
	my $html_tmp_dir = $config->get('html_tmp_dir');
	unless (-d $html_tmp_dir) {
	    mkdir $html_tmp_dir, 0755;
	}

	use File::Spec;
	my $png_filename = sprintf("%s.png", $session_id);
	my $image_file   = File::Spec->catfile($html_tmp_dir, $png_filename);

	use FileHandle;
	my $wh = new FileHandle "> $image_file";
	if (defined $wh) {
	    $wh->binmode();
	    $wh->print($png);
	    $wh->close();
	}

	my $url_base = $config->{ html_tmp_base_url };
	my $url = sprintf("%s/%s", $url_base, $png_filename);
	printf("\n<p>%s\n\n<image src=\"%s\">\n", $name_magic, $url);
    }
}


# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_title
{
    my ($curproc) = @_;
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
    my $msg_args  = $curproc->_gen_msg_args();

    print "<B>\n<CENTER>\n";
    print "$ml_name\@$ml_domain ML\n";
    print "</CENTER><BR>\n</B>\n";
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

Copyright (C) 2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::CGI::Skin::Anonymous appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
