#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Switch.pm,v 1.77 2002/11/16 14:24:46 fukachan Exp $
#

package FML::Process::Switch;

use strict;
use Carp;
use vars qw($debug);
use File::Spec;


=head1 NAME

FML::Process::Switch - dispatch a module suitable with the program name

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
            |  <---  $obj = FML::Process:Distribute
            |
            V
       ProcessStart($obj,$args) Process::Flow


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
    if ($myname eq 'loader') {
	print "ARGV: @ARGV\n";
    }

    # 1.1 parse command line options (preliminary)
    {
	my (@options) = _module_specific_options($myname);
	if (@options) {
	    eval q{
		use Getopt::Long;
		GetOptions(\%options, @options);
	    };
	    croak($@) if $@;
	}
    }

    # 2.1 prepare @$cf
    #     XXX hmm, .. '/etc/fml/site_default_config.cf' is good ???
    my $cf = ();
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
    if ($myname eq 'loader') {
	eval q{
	    require Data::Dumper; Data::Dumper->import();
	    $Data::Dumper::Varname = 'main_cf';
	    print Dumper( $main_cf );
	    sleep 3;
	};
	if ($@) { print STDERR $@; sleep 3;}
    }

    # 5. o.k. here we go!
    #    XXX CAN WE MOVE PARSER TO Process::{Kernel,CGI::Kernel} ?
    #    XXX ml_name, ml_domain, ml_home_prefix, ml_home_dir
    my $args = {
	fml_version    => $main_cf->{ fml_version },

	myname         => $myname,
	program_name   => $myname,

	#    XXX CAN WE MOVE PARSER TO Process::{Kernel,CGI::Kernel} ?
	#    XXX ml_name, ml_domain, ml_home_prefix, ml_home_dir
	# ml_home_prefix => $ml_home_prefix,
	# ml_home_dir    => $main_cf->{ ml_home_dir },

	cf_list        => $cf,       # site_default + default
	options        => \%options, # options parsed by getopt()

	argv           => \@argv,    # pass the original @ARGV
	ARGV           => \@ARGV,    # @ARGV after getopts()

	main_cf        => $main_cf,

	# options
	need_ml_name   => _ml_name_is_required($myname),
    };

    # get the object. The suitable module is speculcated by $0.
    my $obj = ProcessSwitch($myname, $args);

    # start the process.
    eval q{
      FML::Process::Flow::ProcessStart($obj, $args);
    };
    if ($@) {
	my $reason = $@;
	if ($obj->can('help')) { eval $obj->help();};

	eval q{ __log($main_cf, $reason);};

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


# Descriptions: try to save the error message
#    Arguments: HASH_REF($main_cf) STR($s)
# Side Effects: save message to a log file if could
# Return Value: none
sub __log
{
    my ($main_cf, $s) = @_;

    eval q{
	use File::Spec;
	use FileHandle;
	my $dir  = $main_cf->{ ml_home_prefix };
	my $logf = File::Spec->catfile($dir, '@log.crit@');
	my $wh   = new FileHandle ">> $logf";
	if (defined $wh) {
	    print $wh time, "\t", $s, "\n";
	    $wh->close;
	}
    };
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
    my ($myname, $args) = @_;

    # Firstly, create process
    # $pkg is a  package name, for exampl,e "FML::Process::Distribute".
    my $pkg = _module_we_use($args);
    unless (defined $pkg) {
	croak("$args->{ myname } is unknown program\n");
    }

    # debug, ignore this
    if ($myname eq 'loader') { print "use $pkg\n"; sleep 2;}

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
	$myname eq 'digest'     ||
	$myname eq 'mead'       ||
	$myname eq 'error'      ||
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
    elsif ($myname eq 'fmladdr') {
	return qw(debug! help! -c=s n!);
    }
    elsif ($myname eq 'fmlalias') {
	return qw(debug! help! -c=s n!);
    }
    elsif ($myname eq 'fmlsummary') {
	return qw(debug! help! -c=s n!);
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
    elsif ($myname eq 'fmlspool') {
	return qw(debug! help! -I=s convert! style=s srcdir=s);
    }
    else {
	croak "no such program $myname.\n";
    }
}


# Descriptions: this program ($0) requires ML name always or not?
#    Arguments: STR($myname)
# Side Effects: none
# Return Value: NUM(1 (require ml name always) or 0)
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
    elsif ($myname eq 'fmladdr') {
	return 0;
    }
    elsif ($myname eq 'fmlalias') {
	return 0;
    }
    elsif ($myname eq 'fmlhtmlify') {
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
    elsif ($name eq 'mead' || $name eq 'error') {
	$pkg = 'FML::Process::Error';
    }
    elsif ($name eq 'digest') {
	$pkg = 'FML::Process::Digest';
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
    elsif ($name eq 'fmladdr') {
	$pkg = 'FML::Process::Addr';
    }
    elsif ($name eq 'fmlalias') {
	$pkg = 'FML::Process::Alias';
    }
    elsif ($name eq 'fmlsummary') {
	$pkg = 'FML::Process::Summary';
    }
    elsif ($name eq 'fmlthread') {
	$pkg = 'FML::Process::ThreadTrack';
    }
    elsif ($name eq 'fmlthread.cgi' ||
	   $name eq 'thread.cgi'    ||
	   $name eq 'threadview.cgi') {
	$pkg = 'FML::CGI::ThreadTrack';
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
    elsif ($name eq 'fmlspool') {
	$pkg = 'FML::Process::Spool';
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

=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Switch first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
