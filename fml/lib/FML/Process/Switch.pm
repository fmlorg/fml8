#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Switch.pm,v 1.58 2002/03/30 11:08:36 fukachan Exp $
#

package FML::Process::Switch;

use strict;
use Carp;
use vars qw($debug);
use File::Spec;

=head1 NAME

FML::Process::Switch - dispatch the suitable module

=head1 SYNOPSIS

used in C<libexec/loader>.

   package main;
   use FML::Process::Switch;
   &Bootstrap2($main_cf_file); # main::Bootstrap2()

=head1 DESCRIPTION

C<libexec/loader> (C<libexec/fml/loader>), the wrapper, loads this
program and calls C<Bootstrap2()>.
C<Bootstrap2()> loads main.cf,
analyzes the command arguments
and call C<ProcessSwitch()> finally.

C<ProcessSwitch()> emulates "use $package" to load
module suitable with the arguments.
The fml flow bifurcates here through C<ProcessSwitch()>.

The flow details of program exists in FML::Process:: class.
For example, libexec/distribute (fml.pl) runs in this way.

       functions                class
       ----------------------------------------

       main::Bootstrap()        libexec/loader
            |
            V
       main::Bootstrap2()       Process::Switch
            |
            V
       ProcessSwitch()          Process::Switch
            |
            V
       FML::Process:Distribute  FML::Process::Distribute


=head1 FUNCTIONS

=head2 C<main::Bootstrap2()>

kick off the second phase of bootstrap.

It reads *.cf files, parses them and set the result to C<@cf>
array variable.
We pass it to C<ProcessSwitch()> later.

    @cf = (
	   /etc/fml/defaults/$VERSION/default_config.cf
	   /etc/fml/site_default_config.cf (required ?)
	   /etc/fml/domains/$DOMAIN/default_config.cf
	   /var/spool/ml/elena/config.cf
	   );

=cut


# Descriptions: the second phase of bootstrap
#    Arguments: STR($main_cf_file) HASH_REF($main_cf)
# Side Effects: none
# Return Value: same as FML::Process::Flow::ProcessStart()
sub main::Bootstrap2
{
    my ($main_cf_file, $main_cf) = @_;
    my @argv        = @ARGV; # save the original argument vector
    my @cf          = ();
    my %options     = ();
    my $ml_home_dir = ''; # e.g. /var/spool/ml/elena

    use File::Basename;
    my $myname      = basename($0); # inspect my name from $0

    # 0.1
    print STDERR "\nsetuid is not set $< != $>\n\n" if $< != $>;
    print STDERR "\nsetgid is not set $( != $)\n\n" if $( ne $);

    # 0.2
    if ($0 =~ /loader/) {
	print "ARGV: @ARGV\n";
    }

    # 1.1 parse command line options (preliminary)
    {
	my (@options) = _module_specific_options($myname);
	if (@options) {
	    eval q{
		use Getopt::Long;
		GetOptions(\%options, _module_specific_options($myname));
	    };
	    croak($@) if $@;
	}
    }

    # 2.1 analyze main.cf and get the result in $main_cf
    #     removed.

    # 2.2 parse @ARGV and get a list of configuration files
    #     XXX $main_cf{ ml_home_dir } (e.g. /var/spool/ml/elena) is defined
    #         if possible.
    #     a) resolve $ml_name (e.g. expand "elena" to "/var/spool/ml/elena")
    #     b) but we need special treatment in some cases e.g. makefml
    my $cf = _parse_argv($myname, $main_cf);

    # 2.3 prepare @$cf
    #     XXX hmm, .. '/etc/fml/site_default_config.cf' is good ???
    my $sitedef =
      File::Spec->catfile($main_cf->{ config_dir }, 'site_default_config.cf');
    unshift(@$cf, $sitedef);
    unshift(@$cf, $main_cf->{ default_config_cf });

    # 3.1 set up @INC
    unshift(@INC, split(/\s+/, $main_cf->{ lib_dir }));
    unshift(@INC, split(/\s+/, $main_cf->{ local_lib_dir }));

    # 3.2 useful for e.g. "fmldoc"
    $ENV{'PERL5LIB'} = $main_cf->{ lib_dir };

    # 4. debug
    if ($0 =~ /loader/) {
	eval q{
	    require Data::Dumper; Data::Dumper->import();
	    $Data::Dumper::Varname = 'main_cf';
	    print Dumper( $main_cf );
	    sleep 3;
	};
	if ($@) { print STDERR $@;}
    }

    # 5. o.k. here we go!
    use FML::Process::Utils;
    my $ml_home_prefix = FML::Process::Utils::__ml_home_prefix_from_main_cf($main_cf);
    my $args = {
	fml_version    => $main_cf->{ fml_version },

	myname         => $myname,
	program_name   => $myname,
	ml_home_prefix => $ml_home_prefix,
	ml_home_dir    => $main_cf->{ ml_home_dir },

	cf_list        => $cf,
	options        => \%options,

	argv           => \@argv, # pass the original @ARGV
	ARGV           => \@ARGV, # @ARGV after getopts()

	main_cf        => $main_cf,

	# options
	need_ml_name   => _ml_name_is_required($myname),
    };

    # get the object. The suitable module is speculcated by $0.
    my $obj = ProcessSwitch($args);

    # start the process.
    eval q{
      FML::Process::Flow::ProcessStart($obj, $args);
    };
    if ($@) {
	my $reason = $@;
	if ($obj->can('help')) { eval $obj->help();};

	if (defined( $main_cf->{ debug } ) ||
	    defined $options{debug}) {
	    croak($reason);
	}
	else {
	    $reason =~ s/[\n\s]*\s+at\s+.*$//m;
	    croak($reason);
	}
    }
}


# Descriptions: analyze argument vector
#    Arguments: STR($myname) HASH_REF($main_cf)
# Side Effects: none
# Return Value: HASH_ARRAY (list of config.cf's)
sub _parse_argv
{
    my ($myname, $main_cf) = @_;

    if ($myname eq 'makefml') {
	_makefml_parse_argv($myname, $main_cf);
    }
    else {
	_usual_parse_argv($myname, $main_cf);
    }
}


# Descriptions: analyze argument vector
#    Arguments: STR($myname) HASH_REF($main_cf)
# Side Effects: none
# Return Value: HASH_ARRAY (list of config.cf's)
sub _usual_parse_argv
{
    my ($myname, $main_cf) = @_;
    use FML::Process::Utils;
    my $ml_home_prefix = FML::Process::Utils::__ml_home_prefix_from_main_cf($main_cf);
    my $ml_home_dir    = '';
    my $found_cf       = 0;
    my @cf             = ();

    # "elena" is translated to "/var/spool/ml/elena"
    for (@ARGV) {
	# 1. for the first time
	#   a) speculate "/var/spool/ml/$_" looks a $ml_home_dir ?
	unless ($found_cf) {
	    my $x  = File::Spec->catfile($ml_home_prefix, $_);
	    my $cf = File::Spec->catfile($x, "config.cf");
	    if (-d $x && -f $cf) {
		$found_cf    = 1;
		$ml_home_dir = $x;
		push(@cf, $cf);
	    }
	}

	# 2. /var/spool/ml/elena looks a $ml_home_dir ?
	if (-d $_) {
	    $ml_home_dir = $_;
	    my $cf = File::Spec->catfile($_, "config.cf");
	    if (-f $cf) {
		push(@cf, $cf);
		$found_cf = 1;
	    }
	}
	# 3. looks a file, so /var/spool/ml/elena/config.cf ?
	elsif (-f $_) {
	    push(@cf, $_);
	}
    }

    # save $ml_home_dir value in $main_cf directly
    $main_cf->{ ml_home_dir } = $ml_home_dir;

    \@cf;
}


# Descriptions: analyze argument vector
#    Arguments: STR($myname) HASH_REF($main_cf)
# Side Effects: none
# Return Value: HASH_ARRAY (list of config.cf's)
sub _makefml_parse_argv
{
    my ($myname, $main_cf) = @_;
    use FML::Process::Utils;
    my $ml_home_prefix = 
      FML::Process::Utils::__ml_home_prefix_from_main_cf($main_cf);

    # makefml specific syntax.
    if (@ARGV) {
	my @cf = ();
	my ($command, $ml_name, @options) = @ARGV;

	if ($command =~ /\-\>/) {
	    ($command, @options) = @ARGV;
	    ($ml_name, $command) = split('->', $command);
	}
	elsif ($command =~ /::/) {
	    ($command, @options) = @ARGV;
	    ($ml_name, $command) = split('::', $command);
	}

	# save $ml_home_dir value in $main_cf directly
	if (defined $ml_name) {
	    $main_cf->{ ml_home_dir } = 
	      File::Spec->catfile($ml_home_prefix, $ml_name);
	    # config.cf
	    my $cf = 
	      File::Spec->catfile($ml_home_prefix, $ml_name, "config.cf");
	    @cf = ($cf);
	}
	else {
	    warn("\$ml_name not specified");
	}

	return \@cf;
    }
    else {
	return [];
    }
}


=head2 C<ProcessSwitch($args)>

load the library and prepare environment to use it.
C<ProcessSwitch($args)> return process object C<$obj>.

To start the process, we pass C<$obj> with C<$args> to
C<FML::Process::Flow::ProcessStart($obj, $args)>.

C<$args> is like this:

    my $args = {
	fml_version    => $main_cf->{ fml_version },

	myname         => $myname,
	ml_home_prefix => $main_cf->{ ml_home_prefix },
	ml_home_dir    => $main_cf->{ ml_home_dir },

	cf_list        => $cf,
	options        => \%options,

	argv           => \@argv, # pass the original @ARGV
	ARGV           => \@ARGV, # @ARGV after getopts()

	main_cf        => $main_cf,

	# options
	need_ml_name   => _ml_name_is_required($myname),
    };

    # get the object. The suitable module is speculcated by $0.
    my $obj = ProcessSwitch($args);

    # start the process.
    FML::Process::Flow::ProcessStart($obj, $args);

=cut


# Descriptions: top level process switch
#               emulates "use $package" but $package is dynamically
#               determined by e.g. $0.
#    Arguments: HASH_REF($args)
# Side Effects: process switching :-)
#               ProcessSwtich() is exported to main:: Name Space.
# Return Value: STR(package name)
sub ProcessSwitch
{
    my ($args) = @_;

    # Firstly, create process
    # $pkg is a  package name, for exampl,e "FML::Process::Distribute".
    my $pkg = _module_we_use($args);
    unless (defined $pkg) {
	croak("$args->{ myname } is unknown program\n");
    }

    # debug, ignore this
    if ($0 =~ /loader/) { print "use $pkg\n"; sleep 2;}

    eval qq{ require $pkg; $pkg->import();};
    croak($@) if $@;

    return $pkg;
}


# Descriptions: return the suitable getopt options
#    Arguments: STR($myname)
# Side Effects: none
# Return Value: ARRAY (getopt parameters)
sub _module_specific_options
{
    my ($myname) = @_;

    # XXX Caution!
    # XXX xxx.cgi SHOULD NOT ACCPET the same options as command line
    # XXX program xxx does.
    if ($myname eq 'fml.pl'     ||
	$myname eq 'distribute' ||
	$myname eq 'command'    ||
	$myname eq 'loader' ) {
	return qw(ctladdr! debug! help! params=s -c=s);
    }
    elsif ($myname eq 'fmlthread') {
	return qw(debug! help!
		  article_id_max=i
		  spool_dir=s
		  base_url=s
		  msg_base_url=s
		  reverse!
		  params=s -f=s -c=s);
    }
    elsif($myname eq 'thread.cgi'    ||
	  $myname eq 'fmlthread.cgi' ||
	  $myname eq 'threadview.cgi') {
	return ();
    }
    elsif ($myname eq 'fmlconf') {
	return qw(debug! help! params=s -c=s n!);
    }
    elsif ($myname eq 'fmldoc') {
	# perldoc [-h] [-v] [-t] [-u] [-m] [-l]
	return qw(debug! help! params=s -c=s v! t! u! m! l!);
    }
    elsif ($myname eq 'makefml') {
	return qw(debug! help! force! params=s -c=s);
    }
    elsif ($myname eq 'config.cgi' || $myname eq 'menu.cgi') {
	return ();
    }
    elsif ($myname eq 'fmlsch') {
	return qw(debug! help! -D=s -F=s -m=s a! h!);
    }
    elsif ($myname eq 'fmlsch.cgi') {
	return ();
    }
    elsif ($myname eq 'fmlhtmlify') {
	return qw(debug! help! -I=s);
    }
    else {
	croak "no such program $myname.\n";
    }
}


# Descriptions: this program ($0) requires ML name always or not?
#    Arguments: STR($myname)
# Side Effects: none
# Return Value: 1 (require ml name always) or 0
sub _ml_name_is_required
{
    my ($myname) = @_;

    if ($myname eq 'fmldoc') {
	return 0;
    }
    elsif ($myname eq 'fmlsch' || $myname eq 'fmlsch.cgi') {
	return 0;
    }
    elsif ($myname eq 'makefml') {
	return 0;
    }
    elsif ($myname eq 'menu.cgi'   ||
	   $myname eq 'config.cgi' ||
	   $myname eq 'thread.cgi') {
	return 0;
    }
    else {
	return 1;
    }
}


# Descriptions: determine package we need and require() it if needed.
#    Arguments: HASH_REF($args)
# Side Effects: none
# Return Value: STR(FML::Process::SOMETHING module name)
sub _module_we_use
{
    my ($args) = @_;
    my $name   = $args->{ myname };
    my $pkg    = '';

    if (($name eq 'fml.pl' && $args->{ options }->{ ctladdr }) ||
	$name eq 'command' ||
	($name eq 'loader' && $args->{ options }->{ ctladdr })) {
	$pkg = 'FML::Process::Command';
    }
    elsif ($name eq 'fml.pl' || $name eq 'distribute' || $name eq 'loader') {
	$pkg = 'FML::Process::Distribute';
    }
    elsif ($name eq 'fmlserv') {
	$pkg = 'FML::Process::ListServer';
    }
    elsif ($name eq 'fmldoc') {
	$pkg = 'FML::Process::DocViewer';
    }
    elsif ($name eq 'fmlconf') {
	$pkg = 'FML::Process::ConfViewer';
    }
    elsif ($name eq 'makefml') {
	$pkg = 'FML::Process::Configure';
    }
    elsif ($name eq 'fmlthread') {
	$pkg = 'FML::Process::ThreadTrack';
    }
    elsif ($name eq 'fmlthread.cgi' ||
	   $name eq 'thread.cgi'    ||
	   $name eq 'threadview.cgi') {
	$pkg = 'FML::CGI::ThreadTrack';
    }
    elsif ($name eq 'mead') {
	$pkg = 'FML::Process::MailErrorAnalyzer';
    }
    elsif ($name eq 'qmail-ext') {
	$pkg = 'FML::Process::QMail';
    }
    elsif ($name eq 'menu.cgi') {
	$pkg = 'FML::CGI::Admin::Menu';
    }
    elsif ($name eq 'config.cgi') {
	$pkg = 'FML::CGI::Admin::Menu';
    }
    elsif ($name eq 'fmlsch') {
	$pkg = 'FML::Process::Calender';
    }
    elsif ($name eq 'fmlsch.cgi') {
	$pkg = 'FML::CGI::Calender';
    }
    elsif ($name eq 'fmlhtmlify') {
	$pkg = 'FML::Process::HTMLify';
    }
    else {
	return '';
    }

    print STDERR "module = $pkg (for $0)\n" if $debug;

    return $pkg;
}


=head1 SEE ALSO

L<FML::Process::Distribute>,
L<FML::Process::Command>,
L<FML::Process::ListServer>,
L<FML::Process::Configure>,
L<FML::Process::ThreadTrack>,
L<FML::Process::MailErrorAnalyzer>

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Switch appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
