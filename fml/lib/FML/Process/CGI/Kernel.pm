#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.68 2003/12/24 14:24:14 fukachan Exp $
#

package FML::Process::CGI::Kernel;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;
use File::Spec;

# load standard CGI routines
use CGI qw/:standard/;

use FML::Log qw(Log LogWarn LogError);
use FML::Process::Kernel;
use FML::Process::CGI::Utils;
@ISA = qw(FML::Process::CGI::Utils FML::Process::Kernel);


=head1 NAME

FML::Process::CGI::Kernel - CGI core functions

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

ordinary constructor which is used widely in FML::Process classes.

=cut


# Descriptions: ordinary constructor.
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
    $curproc->set_print_style( 'html' );

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

    $curproc->_cgi_resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );
    $curproc->fix_perl_include_path();

    # modified for admin/*.cgi
    unless ($curproc->cgi_var_ml_name()) {
	$curproc->_cgi_fix_log_file();
    }

    # fix charset
    $curproc->_set_charset();

    my $charset = $curproc->get_charset("cgi"); # updated charset.
    print header(-type    => "text/html; charset=$charset",
		 -charset => $charset,
		 -target  => "_top");
}


# Descriptions: update the current charset
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub _set_charset
{
    my ($curproc) = @_;
    my $lang =
	$curproc->cgi_var_language() || $curproc->_http_accept_language();

    use Mail::Message::Charset;
    my $obj     = new Mail::Message::Charset;
    my $charset = $obj->language_to_internal_charset($lang);

    if ($charset) {
	$curproc->set_charset("template_file", $charset);
    }
    else {
	my $default = $obj->internal_default_charset();
	$curproc->set_charset("template_file", $default);
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


# Descriptions: analyze data input from CGI
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: update $config{ ml_* }, $args->{ cf_list }
# Return Value: none
sub _cgi_resolve_ml_specific_variables
{
    my ($curproc, $args) = @_;
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

	# fix $args { cf_list, ml_home_dir };
	my $cflist = $args->{ cf_list };
	push(@$cflist, $config_cf);
    }
    else {
	$curproc->log("debug: no ml_name");
    }

    $curproc->__debug_ml_xxx('cgi:');
}


# Descriptions: fix logging system for admin/*.cgi
#    Arguments: OBJ($curproc)
# Side Effects: update variables.
# Return Value: none
sub _cgi_fix_log_file
{
    my ($curproc) = @_;
    my $config    = $curproc->config();

    $config->set('ml_home_dir', $config->{ domain_local_tmp_dir  });
    $config->set('log_file',    $config->{ domain_local_log_file });
    $curproc->log("debug: log_file = $config->{ log_file }");
}


=head2 verify_request()

dummy method now.

=head2 finish()

dummy method now.

=cut

# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub verify_request { 1;}

# Descriptions: dummy
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub finish { 1;}


=head2 run()

dispatch *.cgi programs.

FML::CGI::XXX module should implement these routines:
star_html(), run_cgi() and end_html().

C<run()> executes

    $curproc->start_html($args);
    $curproc->run_cgi($args);
    $curproc->end_html($args);

C<run_cgi()> prepares tables by the following granularity.

   nw   north  ne
   west center east
   sw   south  se

C<run_cgi_main()> shows at the center and
C<run_cgi_navigation_bar()> at the west by default.
You can specify the location by configure() access method.

=cut


# Descriptions: run FML::CGI::* methods
#                  html_start()
#                  run_cgi()
#                  html_end()
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run
{
    my ($curproc, $args) = @_;

    $curproc->html_start($args);
    $curproc->_drive_cgi_by_table($args);
    $curproc->html_end($args);
}


# Descriptions: show error string
#    Arguments: OBJ($curproc) STR($r)
# Side Effects: none
# Return Value: none
sub _error_string
{
    my ($curproc, $r) = @_;
    my ($key, $msg) = $curproc->parse_exception($r);
    my $nlmsg       = $curproc->message_nl($key);

    if ($r =~ /__ERROR_cgi\.insecure__/) {
	if ($nlmsg) {
	    print "<B>Error! $nlmsg </B>\n";
	}
	else {
	    print "<B>Error! insecure input.</B>\n";
	}
    }
    else {
	print "<B>Error! unknown reason.</B>\n";
    }

    eval q{
	use FML::Log qw(Log LogError);
	$curproc->logerror($r);
	my ($k, $v);
	while (($k, $v) = each %ENV) { $curproc->log("$k => $v");}
    };
}


# Descriptions: show menu table
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub _drive_cgi_by_table
{
    my ($curproc, $args) = @_;
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

    my $td_attr = {
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
    $curproc->run_cgi_main($args);

    print "<table border=0 cellspacing=\"0\" cellpadding=\"5\">\n";
    print "\n<!-- new line -->\n";
    print "\n<tr>\n";
    for my $pos ('nw', 'north', 'ne',
		 '!',
		 'west', 'center', 'east',
		 '!',
		 'sw', 'south', 'se') {
	if ($pos eq '!') {
	    print "</tr>\n";
	    print "\n<!-- new line -->\n";
	    print "\n<tr>\n";
	    next;
	}

	my $attr = $td_attr->{ $pos };
	print "\n<!-- $pos -->\n";
	print $attr ? "<td $attr>\n" : "<td>\n";

	my $fp   = $function_table->{ $pos };
	if ($fp) {
	    eval q{ $curproc->$fp($args);};
	    if ($r = $@) { _error_string($curproc, $r);}
	}
	print "\n</td>\n";
    }
    print "\n</tr>\n";
    print "</table>\n";
}


=head2 cgi_execute_command($args, $command_args)

execute specified command given as FML::Command::*

=cut


# Descriptions: execute FML::Command
#    Arguments: OBJ($curproc) HASH_REF($args) HASH_REF($command_args)
# Side Effects: load module
# Return Value: none
sub cgi_execute_command
{
    my ($curproc, $args, $command_args) = @_;
    my $commode = $command_args->{ command_mode };
    my $comname = $command_args->{ comname };
    my $config  = $curproc->config();

    unless ($config->has_attribute("commands_for_admin_cgi", $comname)) {
	$curproc->logerror("cgi deny command: mode=$commode level=cgi");

	# XXX-TODO: validate $comname (CSS).
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
	my $comname = $command_args->{ comname };
	eval q{
	    $obj->$comname($curproc, $command_args);
	};
	unless ($@) {
	    # XXX-TODO: validate $comname (CSS).
	    print "OK! $comname succeed.\n";
	}
	else {
	    print "Error! $comname fails.\n<BR>\n";
	    if ($@ =~ /^(.*)\s+at\s+/) {
		my $reason    = $@;
		my ($key, $r) = $curproc->parse_exception($reason);
		my $buf       = $curproc->message_nl($key);

		# XXX-TODO: validate output.
		print "<BR>\n";
		print ($buf || $reason);
		print "<BR>\n";
	    }
	}
    }
}


=head2 run_cgi_title($args)

show title.

=cut


# Descriptions: show title
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_title
{
    my ($curproc, $args) = @_;
    my $myname    = $curproc->cgi_var_myname();
    my $ml_domain = $curproc->cgi_var_ml_domain();
    my $ml_name   = $curproc->cgi_var_ml_name();
    my $role      = '';
    my $title     = '';

    if ($myname =~ /thread/) {
	$role  = "for thread view";
    }
    elsif ($myname =~ /config|menu/) {
	$role  = $curproc->message_nl('term.config_interface');
    }

    $title = "${ml_name}\@${ml_domain} CGI $role";
    print $title;
}


=head2 run_cgi_help($args)

help.

=cut


# Descriptions: show help
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_help
{
    my ($curproc, $args) = @_;
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


=head2 run_cgi_command_help($args)

command_help.

=cut


# Descriptions: show command_dependent help
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_command_help
{
    my ($curproc, $args) = @_;
    my $buf          = '';
    my $navi_command = $curproc->safe_param_navi_command();
    my $command      = $curproc->safe_param_command();
    my $msg_args     = $curproc->_gen_msg_args();

    # natural language-ed name
    my $name_usage   = $curproc->message_nl('term.usage',  'usage');

    if ($navi_command) {
	print "[$name_usage]<br> <b> $navi_command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.$navi_command", '', $msg_args);
    }
    elsif ($command) {
	print "[$name_usage]<br> <b> $command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.$command", '', $msg_args);
    }

    print $buf;
}


# Descriptions: prepare arguemnts for message handling.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: HASH_REF
sub _gen_msg_args
{
    my ($curproc, $args) = @_;

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


=head2 run_cgi_log($args)

log.

=cut


# Descriptions: show log
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_log
{
    my ($curproc, $args) = @_;

    # XXX-TODO: NOT IMPLEMENTED.
}


=head2 run_cgi_dummy($args)

dummy.

=cut


# Descriptions: show dummy
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_dummy
{
    my ($curproc, $args) = @_;

    # XXX-TODO: NOT IMPLEMENTED.
}


=head2 run_cgi_date($args)

date.

=cut


# Descriptions: show date
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_date
{
    my ($curproc, $args) = @_;

    # XXX-TODO: NOT IMPLEMENTED. NOT USE `date`;
    print `date`;
}


=head2 run_cgi_options($args)

show options.

=cut


# Descriptions: show options
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub run_cgi_options
{
    my ($curproc, $args) = @_;
    my $domain   = $curproc->cgi_var_ml_domain();
    my $action   = $curproc->safe_cgi_action_name();
    my $lang     = $curproc->cgi_var_language();
    my $config   = $curproc->config();
    my $langlist = $config->get_as_array_ref('cgi_language_list');

    if ($#$langlist > 0) {
	# natural language-ed name
	my $name_options = $curproc->message_nl('term.options',  'options');
	my $name_lang    = $curproc->message_nl('term.language', 'language');
	my $name_change  = $curproc->message_nl('term.change',   'change');
	my $name_reset   = $curproc->message_nl('term.reset',    'reset');

	print "<P> <B> $name_options </B>\n";

	print start_form(-action=>$action);

	print $name_lang, ":\n";
	print scrolling_list(-name    => 'language',
			     -values  => $langlist,
			     -default => [ $lang ],
			     -size    => 1);

	print submit(-name => $name_change);
	print reset(-name  => $name_reset);

	print end_form;
    }
}


=head2 run_cgi_menu($args, $comname, $command_args)

execute cgi_menu() given as FML::Command::*

=cut


# Descriptions: execute FML::Command
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: load module
# Return Value: none
sub run_cgi_menu
{
    my ($curproc, $args) = @_;
    my $pcb          = $curproc->pcb();
    my $command_args = $pcb->get('cgi', 'command_args');

    if (defined $command_args) {
	# XXX-TODO: validate $comname
	my $comname = $command_args->{ comname };
	my $cmd     = "FML::Command::Admin::$comname";
	my $obj     = undef;
	eval qq{
	    use $cmd;
	    \$obj = new $cmd;
	};

	if (defined $obj) {
	    $obj->cgi_menu($curproc, $args, $command_args);
	}
    }
    else {
	my $ml_name = $curproc->safe_param_ml_name();

	if ($ml_name) {
	    $curproc->run_cgi_help($args);
	}
	else {
	    $curproc->run_cgi_help($args);
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


=head2 cgi_try_get_address()

return input address after validating the input

=cut


# Descriptions: return input address after validating the input
#    Arguments: OBJ($curproc)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_address
{
    my ($curproc) = @_;
    my $address = '';
    my $a = '';

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
	if ($curproc->is_safe_syntax('address', $address)) {
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


# Descriptions: return input ml_name after validating the input
#    Arguments: OBJ($curproc)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_ml_name
{
    my ($curproc) = @_;
    my $ml_name = '';
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
	if ($curproc->is_safe_syntax('ml_name', $ml_name)) {
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

    if ($curproc->is_safe_syntax('action', $name)) {
	return $name;
    }
    else {
	return undef;
    }
}


=head2 safe_param_xxx()

get and filter param('xxx') via AUTOLOAD().

=cut


# Descriptions: trap safe_param_XXX()
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
        croak("__ERROR_cgi.unknown_method__: unknown method $comname");
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Kernel first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
