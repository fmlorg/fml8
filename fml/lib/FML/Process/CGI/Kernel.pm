#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Kernel.pm,v 1.22 2002/04/10 09:51:26 fukachan Exp $
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
    my $is_need_ml_name = $args->{ 'need_ml_name' };

    # we should get $ml_name from HTTP.
    use FML::Process::Utils;
    my $ml_home_prefix = FML::Process::Utils::__ml_home_prefix_from_main_cf($args);
    my $ml_name        = safe_param_ml_name($self) || do {
	if ($is_need_ml_name) {
	    croak("not get ml_name from HTTP") if $args->{ need_ml_name };
	}
    };

    use File::Spec;
    my $ml_home_dir = File::Spec->catfile($ml_home_prefix, $ml_name);
    my $config_cf   = File::Spec->catfile($ml_home_dir, 'config.cf');

    # fix $args { cf_list, ml_home_dir };
    my $cflist = $args->{ cf_list };
    push(@$cflist, $config_cf);
    $args->{ ml_home_dir } =  $ml_home_dir;

    # o.k. load configurations
    my $curproc = new FML::Process::Kernel $args;
    return bless $curproc, $type;
}


=head2 C<prepare()>

print HTTP header.
The charset is C<euc-jp> by default.

=cut


# Descriptions: html header.
#               FML::Process::Kernel::prepare() parses incoming_message
#               CGI do not parse incoming_message;
#    Arguments: OBJ($curproc)
# Side Effects: none
# Return Value: none
sub prepare
{
    my ($curproc) = @_;
    my $config    = $curproc->{ config };
    my $charset   = $config->{ cgi_charset } || 'euc-jp';

    print header(-type    => "text/html; charset=$charset",
		 -charset => $charset,
		 -target  => "_top");
}


=head2 C<verify_request()>

dummy method now.

=head2 C<finish()>

dummy method now.

=cut

sub verify_request { 1;}

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
    my ($r) = @_;

    if ($r =~ /ERROR\.INSECURE/) {
	print "<B>Error! insecure input.</B>\n";
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
    # table starts.
    print "<table border=0 cellspacing=\"0\" cellpadding=\"5\">\n";

    # the first line
    print "<tr>\n";
    print "<td>\n";
    print "</td>\n";
    print "<td>\n";

    eval q{ $curproc->run_cgi_title($args);};
    if ($r = $@) { _error_string($r);}

    print "</td>\n";
    print "<td></td>\n";
    print "</tr>\n";

    # the second line
    print "<tr>\n";
    print "<td valign=\"top\" BGCOLOR=\"#E0E0F0\">\n";

    eval q{ $curproc->run_cgi_navigator($args);};
    if ($r = $@) { _error_string($r);}

    print "<td rowspan=2 valign=\"top\">\n";

    eval q{ $curproc->run_cgi_main($args);};
    if ($r = $@) { _error_string($r);}

    print "</td>\n";
    print "<td rowspan=2 valign=\"top\">\n";

    eval q{ $curproc->run_cgi_options($args);};
    if ($r = $@) { _error_string($r);}

    print "</td>\n";
    print "</tr>\n";

    # the 3rd line
    print "<tr>\n";
    print "<td></td>\n";
    print "<td></td>\n";
    print "<td></td>\n";
    print "</tr>\n";

    # table ends.
    print "</table>\n";
}


=head2 get_ml_list($args)

get HASH ARRAY of valid mailing lists.

=cut


# Descriptions: list up ML
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_ml_list
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };

    use File::Spec;
    my $cf = '';

    use DirHandle;
    my $dh = new DirHandle $config->{ ml_home_prefix };
    my @dirlist;
    my $prefix = $config->{ ml_home_prefix };
    while ($_ = $dh->read()) {
	next if /^\./;
	next if /^\@/;
	$cf = File::Spec->catfile($prefix, $_, "config.cf");
	push(@dirlist, $_) if -f $cf;
    }
    $dh->close;

    @dirlist = sort @dirlist;
    return \@dirlist;
}


=head2 get_recipient_list($args)

get HASH ARRAY of valid mailing lists.

=cut


# Descriptions: list up recipients list
#    Arguments: OBJ($curproc) HASH_REF($args)
# Side Effects: none
# Return Value: ARRAY_REF
sub get_recipient_list
{
    my ($curproc, $args) = @_;
    my $config = $curproc->{ config };
    my $list   = $config->get_as_array_ref( 'recipient_maps' );

    eval q{ use IO::Adapter;};
    unless ($@) {
	my $r = [];

	for my $map (@$list) {
	    my $io  = new IO::Adapter $map;
	    my $key = '';
	    $io->open();
	    while (defined($key = $io->get_next_key())) {
		push(@$r, $key);
	    }
	    $io->close();
	}

	return $r;
    }

    return [];
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

    $role  = "for thread view" if $myname =~ /thread/;
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
    print "help<BR>\n";
    print "</B>\n";
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

    print "<B><CENTER> OPTIONS </CENTER></B>\n";

    print start_form(-action=>$action);

    print "Language:\n";
    my $langlist = [ 'Japanese', 'English' ];
    print scrolling_list(-name    => 'language',
			 -values  => $langlist,
			 -size    => 1);

    print submit(-name => 'change');
    # print reset(-name  => 'reset');

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
    my ($curproc, $args, $comname, $command_args) = @_;
    my $cmd = "FML::Command::Admin::$comname";
    my $obj = undef;

    eval qq{
	use $cmd;
	\$obj = new $cmd;
    };

    if (defined $obj) {
	$obj->cgi_menu($curproc, $args, $command_args);
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
	if ($r =~ /ERROR\.INSECURE/) { croak($r);}
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
	    if ($r =~ /ERROR\.INSECURE/) { croak($r);}
	}
    }

    return $address;
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
        croak("unknown method $comname");
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
