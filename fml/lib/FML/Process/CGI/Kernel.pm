#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.38 2002/06/30 14:30:17 fukachan Exp $
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
@ISA = qw(FML::Process::Kernel);


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

=head2 C<new()>

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
    return bless $curproc, $type;
}


=head2 C<prepare($args)>

print HTTP header.
The charset is C<euc-jp> by default.

=cut


# Descriptions: print html header.
#               analyze cgi data to determine ml_name et.al.
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc, $args) = @_;
    my $config    = $curproc->{ config };
    my $charset   = $config->{ cgi_charset } || 'euc-jp';

    $curproc->_cgi_resolve_ml_specific_variables( $args );
    $curproc->load_config_files( $args->{ cf_list } );

    print header(-type    => "text/html; charset=$charset",
		 -charset => $charset,
		 -target  => "_top");
}


# Descriptions: analyze data input from CGI
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: update $config{ ml_* }, $args->{ cf_list }
# Return Value: none
sub _cgi_resolve_ml_specific_variables
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my ($ml_home_dir, $config_cf);

    # inherit ml_domain from $hints
    # which is defined/hard-coded in *.cgi (libexec/loader) script.
    my $hints          = $curproc->hints();
    my $ml_domain      = $hints->{ ml_domain };
    my $ml_home_prefix = $curproc->ml_home_prefix( $ml_domain );

    # cheap sanity
    unless ($ml_home_prefix) {
	my $r = "ml_home_prefix undefined";
	croak("__ERROR_cgi.fail_to_get_ml_home_prefix__: $r");
    }

    # reset
    $config->set('ml_domain',      $ml_domain);
    $config->set('ml_home_prefix', $ml_home_prefix);

    # speculate ml_name, which is not used in some cases.
    my $ml_name = $curproc->safe_param_ml_name() || do {
	my $is_need_ml_name = $args->{ 'need_ml_name' };
	if ($is_need_ml_name) {
	    my $r = "fail to get ml_name from HTTP";
	    croak("__ERROR_cgi.fail_to_get_ml_name__: $r");
	}
    };

    # speculate $ml_home_dir when $ml_name is determined.
    if ($ml_name) {
	use File::Spec;
	$ml_home_dir = $curproc->ml_home_dir($ml_name, $ml_domain);

	$config->set('ml_name',     $ml_name);
	$config->set('ml_home_dir', $ml_home_dir);

	# fix $args { cf_list, ml_home_dir };
	$config_cf = File::Spec->catfile($ml_home_dir, 'config.cf');
	my $cflist = $args->{ cf_list };
	push(@$cflist, $config_cf);
    }

    $curproc->__debug_ml_xxx('cgi:');
}


=head2 C<verify_request()>

dummy method now.

=head2 C<finish()>

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


=head2 C<run()>

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
#    Arguments: STR($r)
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
	LogError($r);
	my ($k, $v);
	while (($k, $v) = each %ENV) { Log("$k => $v");}
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
		print $reason;
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
    my $myname  = $curproc->myname();
    my $domain  = $curproc->ml_domain();
    my $ml_name = $curproc->safe_param_ml_name();
    my $role    = '';
    my $title   = '';

    $role  = "for thread view"   if $myname =~ /thread/;
    $role  = "for configuration" if $myname =~ /config|menu/;
    $title = "${ml_name}\@${domain} CGI $role";
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
    my $domain = $curproc->ml_domain();

    print "<B>\n";
    print "<CENTER>fml CGI interface for \@$domain ML's</CENTER><BR>\n";
    print "</B>\n";

    # top level help message
    my $buf = $curproc->message_nl("cgi.top");
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

    if ($navi_command) {
	print "[Usage]<br> <b> $navi_command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.$navi_command");
    }
    elsif ($command) {
	print "[Usage]<br> <b> $command </b> <br>\n";
	$buf = $curproc->message_nl("cgi.$command");
    }

    print $buf;
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
    my $domain = $curproc->ml_domain();
    my $action = $curproc->myname();

    print "<P> <B> options </B>\n";

    print start_form(-action=>$action);

    print "Language:\n";
    my $langlist = [ 'Japanese', 'English' ];
    print scrolling_list(-name   => 'language',
			 -values => $langlist,
			 -size   => 1);

    print submit(-name => 'change');

    print end_form;
}


=head2 run_cgi_menu($args, $comname, $command_args)

execute cgi_menu() given as FML::Command::*

=cut


# Descriptions: execute FML::Command
#    Arguments: OBJ($curproc) HASH_REF($args)
#               STR($comname) HASH_REF($command_args)
# Side Effects: load module
# Return Value: none
sub run_cgi_menu
{
    my ($curproc, $args) = @_;
    my $pcb          = $curproc->{ pcb };
    my $command_args = $pcb->get('cgi', 'command_args');

    if (defined $command_args) {
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


=head2 cgi_try_get_address()

return input address after validating the input

=cut


# Descriptions: return input address after validating the input
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_address
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

    return $address;
}


=head2 cgi_try_get_address()

return input address after validating the input

=cut


# Descriptions: return input ml_name after validating the input
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: longjmp() if critical error occurs.
# Return Value: STR
sub cgi_try_get_ml_name
{
    my ($curproc, $args) = @_;
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

    return $ml_name;
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
        croak("__ERROR_cgi.unknown_method__: unknown method $comname");
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::CGI::Kernel appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
