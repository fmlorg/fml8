#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.91 2006/03/05 08:08:37 fukachan Exp $
#

package FML::Process::CGI::Kernel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

# load standard CGI routines
use CGI qw/:standard/;

use FML::Process::Kernel;
use FML::Process::CGI::Utils;
@ISA = qw(FML::Process::CGI::Utils FML::Process::Kernel);


=head1 NAME

FML::Process::CGI::Kernel - CGI core functions.

=head1 SYNOPSIS

   use FML::Process::CGI::Kernel;
   my $obj = new FML::Process::CGI::Kernel;
   $obj->prepare($args);
      ... snip ...

This new() creates CGI object which wraps C<FML::Process::Kernel>.

=head1 DESCRIPTION

the base class of CGI programs.
It provides basic functions and flow.

=head1 METHODS

=head2 new()

constructor.

=cut


# Descriptions: constructor.
#               now we re-evaluate $ml_home_dir and @cf again.
#               but we need the mechanism to re-evaluate $args passed from
#               libexec/loader.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my $type = ref($self) || $self;

    # create kernel object and redefine $curproc as the object $type.
    my $curproc = new FML::Process::Kernel $args;

    # print as html if possible.
    $curproc->output_set_print_style( 'html' );

    return bless $curproc, $type;
}


=head2 prepare($args)

print HTTP header.
The charset is C<euc-jp> by default.

adjust ml_*, load config files and fix @INC.

=cut


# Descriptions: print html header.
#               analyze cgi data to determine ml_name et.al.
#               adjust ml_*, load config files and fix @INC.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;

    $curproc->_cgi_ml_variables_resolve();
    $curproc->config_cf_files_load();
    $curproc->env_fix_perl_include_path();

    # modified for admin/*.cgi
    unless ($curproc->cgi_var_ml_name()) {
	$curproc->_cgi_fix_log_file();
    }

    # fix charset
    $curproc->_set_charset();

    my $charset = $curproc->langinfo_get_charset("cgi"); # updated charset.
    print header(-type    => "text/html; charset=$charset",
		 -charset => $charset,
		 -target  => "_top");

    # generate and save the session string and identifier.
    $curproc->_set_anonymous_session_id();
}


# Descriptions: update the current charset.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _set_charset
{
    my ($curproc) = @_;
    my $lang =
	$curproc->cgi_var_language() || $curproc->_http_accept_language();


    # XXX-TODO: $obj ? -> $charset ?
    use Mail::Message::Charset;
    my $obj     = new Mail::Message::Charset;
    my $charset = $obj->language_to_internal_charset($lang);

    if ($charset) {
	$curproc->langinfo_set_charset("template_file", $charset);
    }
    else {
	my $default = $obj->internal_default_charset();
	$curproc->langinfo_set_charset("template_file", $default);
    }
}


# Descriptions: speculate default language preferred by user browser.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub _http_accept_language
{
    my ($curproc) = @_;
    my $r = '';

    if ($ENV{'HTTP_ACCEPT_LANGUAGE'}) {
	my $buf = $ENV{'HTTP_ACCEPT_LANGUAGE'};

      LANG:
	for my $lang (split(/\s*,\s*/, $buf)) {
	    $lang =~ s/\s*;.*$//;
	    if ($lang =~ /^ja/) {
		$r = 'ja';
		last LANG;
	    }
	    elsif ($lang =~ /^en/) {
		$r = 'en';
		last LANG;
	    }
	}
    }

    return $r;
}


# Descriptions: analyze data input from CGI.
#    Arguments: OBJ($curproc)
# Side Effects: update $config{ ml_* }, $args->{ cf_list }
# Return Value: none
sub _cgi_ml_variables_resolve
{
    my ($curproc)      = @_;
    my $config         = $curproc->config();
    my $ml_name        = $curproc->cgi_var_ml_name();
    my $ml_domain      = $curproc->cgi_var_ml_domain();
    my $ml_home_prefix = $curproc->cgi_var_ml_home_prefix();

    # cheap sanity 1.
    unless ($ml_home_prefix) {
	my $r = "ml_home_prefix undefined";
	croak("__ERROR_cgi.fail_to_get_ml_home_prefix__: $r");
    }

    # cheap sanity 2.
    unless ($ml_name) {
	my $is_need_ml_name = $curproc->is_need_ml_name();
	if ($is_need_ml_name) {
	    my $r = "fail to get ml_name from HTTP";
	    croak("__ERROR_cgi.fail_to_get_ml_name__: $r");
	}
    };

    # reset $ml_domain and $ml_home_prefix.
    $config->set('ml_domain',      $ml_domain);
    $config->set('ml_home_prefix', $ml_home_prefix);

    # speculate $ml_home_dir when $ml_name is determined.
    if ($ml_name) {
	use File::Spec;
	my $ml_home_dir = $curproc->ml_home_dir($ml_name, $ml_domain);
	my $config_cf   = $curproc->config_cf_filepath($ml_name, $ml_domain);

	$config->set('ml_name',     $ml_name);
	$config->set('ml_home_dir', $ml_home_dir);

	# XXX-TODO: method name .. hmm. $curproc->$obj_$function().
	# add this ml's config.cf to the .cf list.
	$curproc->config_cf_files_append($config_cf);
    }
    else {
	$curproc->logdebug("no ml_name");
    }

    $curproc->__debug_ml_xxx('cgi:');
}


# Descriptions: fix logging system for admin/*.cgi.
#    Arguments: OBJ($curproc)
# Side Effects: update variables.
# Return Value: none
sub _cgi_fix_log_file
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    $config->set('ml_home_dir', $config->{ domain_local_tmp_dir  });
    $config->set('log_file',    $config->{ domain_local_log_file });
    $curproc->logdebug("log_file = $config->{ log_file }");
}


# Descriptions: generate the session string and identifier and set it.
#    Arguments: OBJ($curproc)
# Side Effects: update pcb and temporary databases.
# Return Value: none
sub _set_anonymous_session_id
{
    my ($curproc) = @_;

    use FML::CGI::Anonymous::DB;
    my $db = new FML::CGI::Anonymous::DB $curproc;
    $db->assign_id();
}


=head2 verify_request()

dummy method now.

=head2 finish()

dummy method now.

=cut

# Descriptions: dummy.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request { 1;}

# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub finish
{
    my ($curproc) = @_;

    $curproc->reply_message_inform();
    $curproc->queue_flush();
}


=head2 run()

dispatch *.cgi programs.

FML::CGI::XXX module should implement these routines:
star_html(), run_cgi() and end_html().

C<run()> executes

    $curproc->html_start();
    $curproc->_drive_cgi_by_table();
    $curproc->html_end();

C<run_cgi()> prepares tables by the following granularity.

   nw   north  ne
   west center east
   sw   south  se

C<run_cgi_main()> shows at the center and
C<run_cgi_navigation_bar()> at the west by default.
You can specify the location by configure() access method.

=cut


# Descriptions: run FML::CGI::* methods:
#                  html_start()
#                  run_cgi()
#                  html_end()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;

    $curproc->html_start();
    $curproc->_drive_cgi_by_table();
    $curproc->html_end();
}


# Descriptions: show error string.
#    Arguments: OBJ($curproc) STR($r)
# Side Effects: none
# Return Value: none
sub _error_string
{
    my ($curproc, $r) = @_;
    my ($key, $msg)   = $curproc->exception_parse($r);
    my $nlmsg         = $curproc->message_nl($key);

    if ($r =~ /__ERROR_cgi\.insecure__/) {
	if ($nlmsg) {
	    print "<B>Error! $nlmsg </B>\n";
	}
	else {
	    print "<B>Error! insecure input.</B>\n";
	}
    }
    else {
	if ($nlmsg) {
	    print "<B>Error! $nlmsg </B>\n";
	}
	else {
	    print "<B>Error! unknown reason.</B>\n";
	}
    }

    eval q{
	$curproc->logerror($r);
	my ($k, $v);
	while (($k, $v) = each %ENV) { $curproc->logdebug("$k => $v");}
    };
}


# Descriptions: show menu table.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _drive_cgi_by_table
{
    my ($curproc) = @_;
    my $r = '';

    # XXX-TODO: hmm, customisable by /etc/fml/cgi.conf ?
    #
    #   nw   north  ne
    #   west center east
    #   sw   south  se
    #
    my $function_table = {
	nw       => '',
	north    => 'run_cgi_title',
	ne       => '',

	'west'   => 'run_cgi_navigator',
	'center' => 'run_cgi_menu',
	'east'   => 'run_cgi_command_help',

	'sw'     => 'run_cgi_options',
	'south'  => '',
	'se'     => '',
    };

    my $td_attr  = {
	nw       => '',
	north    => '',
	ne       => '',

	'west'   => 'valign="top" BGCOLOR="#E0E0F0"',
	'center' => 'rowspan=2 valign="top"',
	'east'   => 'rowspan=2 valign="top"',

	'sw'     => 'valign="top" BGCOLOR="#E0E0F0"',
	'south'  => 'rowspan=2 valign="top"',
	'se'     => 'rowspan=2 valign="top"',
    };

    # firstly, execute command if needed.
    $curproc->run_cgi_main();

    print "<table border=0 cellspacing=\"0\" cellpadding=\"5\">\n";
    print "\n<!-- new line -->\n";
    print "\n<tr>\n";
    for my $pos ('nw',   'north',  'ne',
		 '!',
		 'west', 'center', 'east',
		 '!',
		 'sw',   'south',  'se') {
	if ($pos eq '!') {
	    print "</tr>\n";
	    print "\n<!-- new line -->\n";
	    print "\n<tr>\n";
	    next;
	}

	my $attr = $td_attr->{ $pos };
	print "\n<!-- $pos -->\n";
	print $attr ? "<td $attr>\n" : "<td>\n";

	my $fp = $function_table->{ $pos };
	if ($fp) {
	    eval q{ $curproc->$fp();};
	    if ($r = $@) { _error_string($curproc, $r);}
	}
	print "\n</td>\n";
    }
    print "\n</tr>\n";
    print "</table>\n";
}


=head2 cgi_execute_command($command_context)

execute specified command given as FML::Command::*

=cut


# Descriptions: execute FML::Command.
#    Arguments: OBJ($curproc) OBJ($command_context) STR($mode)
# Side Effects: load module
# Return Value: none
sub cgi_execute_command
{
    my ($curproc, $command_context, $mode) = @_;

    $mode ||= 'admin_cgi';
    if ($mode eq 'ml_anonymous_cgi') {
	$curproc->__cgi_execute_command($command_context,
					$mode,
					"ml_anonymous_cgi_allowed_commands");
    }
    else {
	$curproc->__cgi_execute_command($command_context, 
					$mode,
					"admin_cgi_allowed_commands");
    }
}


# Descriptions: execute FML::Command.
#    Arguments: OBJ($curproc) OBJ($command_context) 
#               STR($mode) STR($var_command_list)
# Side Effects: load module
# Return Value: none
sub __cgi_execute_command
{
    my ($curproc, $command_context, $mode, $var_command_list) = @_;

    # XXX Only FML::CGI::Skin::Base calls cgi_execute_command() now.
    # XXX comname are the result returned by $curproc->safe_param_command().
    # XXX command_mode is hard-coded in FML::CGI::Skin::Base.
    my $commode = $command_context->get_mode();
    my $comname = $command_context->get_cooked_command();
    my $config  = $curproc->config();

    # XXX $comname is one of strings defined in the config file,
    # XXX NOT user defined one.
    unless ($config->has_attribute($var_command_list, $comname)) {
	my $msg = "cgi deny command=$comname mode=$commode level=cgi";
	$curproc->logerror($msg);

	my $buf = $curproc->message_nl("cgi.deny",
				       "Error: deny $comname command");
	print $buf, "<BR>\n";

	return;
    }
    else {
	$curproc->log("run $comname mode=$commode level=cgi");
    }

    use FML::Command;
    my $obj = new FML::Command;
    if (defined $obj) {
	eval q{
	    $obj->$comname($curproc, $command_context);
	};
	unless ($@) {
	    my $buf = '';
	    if ($mode eq 'ml_anonymous_cgi') {
		$buf = $curproc->message_nl("cgi.anonymous.ok",
					    "OK! $comname succeed");
	    }
	    else {
		$buf = $curproc->message_nl("cgi.ok",
					    "OK! $comname succeed");
	    }
	    print $buf, "<br>\n";

	}
	else {
	    my $buf = $curproc->message_nl("cgi.fail",
					   "Error! $comname fails.");
	    print $buf, "<br>\n";
	    if ($@ =~ /^(.*)\s+at\s+/) {
		my $reason    = $1;
		my ($key, $r) = $curproc->exception_parse($reason);
		my $buf       = $curproc->message_nl($key) || undef;
		$curproc->logerror($reason);
		if ($buf) {
		    print "<br>", $buf, "<br>\n";
		}
	    }
	}
    }
}


=head2 run_cgi_title()

show title.

=cut


# Descriptions: show title,
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_title
{
    my ($curproc) = @_;
    my $myname    = $curproc->cgi_var_myname();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $role      = '';
    my $title     = '';

    # XXX-TODO: customizable
    if ($myname =~ /thread/) {
	$role  = "for thread view";
    }
    elsif ($myname =~ /config|menu/) {
	$role  = $curproc->message_nl('term.config_interface');
    }

    $title = "${ml_name}\@${ml_domain} CGI $role";
    print $title;
}


=head2 run_cgi_log()

show log.

=cut


# Descriptions: show log
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_log
{
    my ($curproc) = @_;

    # XXX-TODO: NOT IMPLEMENTED.
}


=head2 run_cgi_dummy()

dummy.

=cut


# Descriptions: dummy.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_dummy
{
    my ($curproc) = @_;

    # XXX-TODO: NOT IMPLEMENTED.
}


=head2 run_cgi_date()

date.

=cut


# Descriptions: show date.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_date
{
    my ($curproc) = @_;

    use Mail::Message::Date;
    my $date = new Mail::Message::Date time;
    print $date->mail_header_style();
}


=head2 run_cgi_options()

show options.

=cut


# Descriptions: show options.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub run_cgi_options
{
    my ($curproc) = @_;
    my $domain    = $curproc->cgi_var_ml_domain();
    my $action    = $curproc->cgi_var_action();
    my $target    = $curproc->cgi_var_frame_target();
    my $lang      = $curproc->cgi_var_language();
    my $config    = $curproc->config();
    my $langlist  = $config->get_as_array_ref('cgi_language_select_list');

    #
    # XXX-TODO: STYLE? safe_cgi_* vs cgi_-var_* vs safe_param_*
    #

    if ($#$langlist > 0) {
	# natural language-ed name
	my $name_options = $curproc->message_nl('term.options',  'options');
	my $name_lang    = $curproc->message_nl('term.language', 'language');
	my $name_switch  = $curproc->message_nl('term.switch',   'switch to');
	my $name_reset   = $curproc->message_nl('term.reset',    'reset');

	print "<P> <B> $name_options </B>\n";
	print "<BR>\n";
	print start_form(-action=>$action, -target=>$target);

	print $name_lang, ":\n";
	print scrolling_list(-name    => 'language',
			     -values  => $langlist,
			     -default => [ $lang ],
			     -size    => 1);

	print "<BR>\n";
	print submit(-name => $name_switch);
	print reset(-name  => $name_reset);

	print end_form;
    }
}


=head2 run_cgi_menu()

execute cgi_menu() given as FML::Command::*

=cut


# Descriptions: execute FML::Command.
#    Arguments: OBJ($curproc)
# Side Effects: load module
# Return Value: none
sub cgi_execute_cgi_menu
{
    my ($curproc)    = @_;
    my $pcb          = $curproc->pcb();
    my $command_context = $pcb->get('cgi', 'command_context');

    # navigation to top menu.
    $curproc->cgi_menu_back_to_top();

    if (defined $command_context) {
	# XXX-TODO: who validate $comname (in FML::CGI::Skin) ?
	my $comname = $command_context->get_cooked_command();
	my $cmd     = "FML::Command::Admin::$comname";
	my $obj     = undef;
	eval qq{
	    use $cmd;
	    \$obj = new $cmd;
	};

	if (defined $obj) {
	    $obj->cgi_menu($curproc, $command_context);
	}
    }
    else {
	my $ml_name = $curproc->safe_param_ml_name();

	if ($ml_name) {
	    $curproc->run_cgi_help();
	}
	else {
	    $curproc->run_cgi_help();
	}
    }
}


=head1 MISC / UTILITIES

=head2 cgi_hidden_info_language()

=cut


# Descriptions: return "<hidden name=language value= ...>" to interact
#               with user browser.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub cgi_hidden_info_language
{
    my ($curproc) = @_;
    my $lang = $curproc->cgi_var_language();

    return hidden(-name    => 'language',
		  -default => [ $lang ]);
}


# Descriptions: show "back to top" menu.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub cgi_menu_back_to_top
{
    my ($curproc) = @_;
    my $target    = $curproc->cgi_var_frame_target();
    my $action    = $curproc->cgi_var_action();

    # XXX-TODO: hard-coded. remove this.
    unless ($0 =~ /config\.cgi/o) {
	print start_form(-action=>$action, -target=>$target);
	print $curproc->cgi_hidden_info_language();

	print hidden(-name => 'navi_command', [ '' ]);
	print hidden(-name => 'command',      [ '' ]);

	my $n = $curproc->message_nl("cgi.select_top", "back to top menu.");
	print submit(-name => $n);
	print end_form;
    }
}


# XXX-TODO: cgi_try_get_address() -> cgi_var_address() ?

=head2 cgi_try_get_address()

return input address after validating the input

=cut


# Descriptions: return input address after validating the input.
#    Arguments: OBJ($curproc)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_address
{
    my ($curproc) = @_;
    my $address   = '';
    my $a         = '';

    eval q{ $a = $curproc->safe_param_address_specified();};
    unless ($@) {
	$address = $a;
    }
    else {
	# XXX longjmp() if insecure input is given.
	my $r = $@;
	if ($r =~ /__ERROR_cgi\.insecure__/) { croak($r);}
    }

    # retry !
    unless ($a) {
	eval q{ $a = $curproc->safe_param_address_selected();};
	unless ($@) {
	    $address = $a;
	}
	else {
	    # XXX longjmp() if insecure input is given.
	    my $r = $@;
	    if ($r =~ /__ERROR_cgi\.insecure__/) { croak($r);}
	}
    }

    if ($address) {
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	if ($safe->regexp_match('address', $address)) {
	    return $address;
	}
	else {
	    croak("__ERROR_cgi\.insecure__: insecure address = $address");
	}
    }

    return $address;
}


=head2 cgi_try_get_address()

return input address after validating the input

=cut


# Descriptions: return input ml_name after validating the input.
#    Arguments: OBJ($curproc)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_ml_name
{
    my ($curproc) = @_;
    my $ml_name   = '';
    my $a = '';

    eval q{ $a = $curproc->safe_param_ml_name_specified();};
    unless ($@) {
	$ml_name = $a;
    }
    else {
	# XXX longjmp() if insecure input is given.
	my $r = $@;
	if ($r =~ /__ERROR_cgi\.insecure__/) { croak($r);}
    }

    # retry !
    unless ($a) {
	eval q{ $a = $curproc->safe_param_ml_name();};
	unless ($@) {
	    $ml_name = $a;
	}
	else {
	    # XXX longjmp() if insecure input is given.
	    my $r = $@;
	    if ($r =~ /__ERROR_cgi\.insecure__/) { croak($r);}
	}
    }

    if ($ml_name) {
	use FML::Restriction::Base;
	my $safe = new FML::Restriction::Base;
	if ($safe->regexp_match('ml_name', $ml_name)) {
	    return $ml_name;
	}
	else {
	    croak("__ERROR_cgi\.insecure__: insecure ml_name = $ml_name");
	}
    }
    else {
	return '';
    }
}


=head2 safe_cgi_action_name

return the current action name,

=cut


# Descriptions: return the current action name,
#               which syntax is checked by regexp.
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: STR
sub safe_cgi_action_name
{
    my ($curproc) = @_;
    my $name = $curproc->myname();

    use FML::Restriction::Base;
    my $safe = new FML::Restriction::Base;
    if ($safe->regexp_match('action', $name)) {
	return $name;
    }
    else {
	return undef;
    }
}


=head2 safe_param_xxx()

get and filter param('xxx') via AUTOLOAD().

=cut


# Descriptions: trap safe_param_XXX().
#    Arguments: OBJ($curproc)
# Side Effects: callback to safe_param*().
# Return Value: depend on safe_param*() return value
sub AUTOLOAD
{
    my ($curproc) = @_;

    return if $AUTOLOAD =~ /DESTROY/;

    my $comname = $AUTOLOAD;
    $comname =~ s/.*:://;

    if ($comname =~ /^(safe_paramlist)(\d+)_(\S+)/) {
        my ($method, $numregexp, $varname) = ($1, $2, $3);
        return $curproc->$method($numregexp, $varname);
    }
    elsif ($comname =~ /^(safe_param)_(\S+)/) {
        my ($method, $varname) = ($1, $2);
        return $curproc->$method($varname);
    }
    else {
	# XXX-TODO: validate $comname
	$curproc->logerror("cannot validate command name.");
        croak("__ERROR_cgi.unknown_method__: unknown method $comname");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004,2005,2006,2008 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
