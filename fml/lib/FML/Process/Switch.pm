#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Switch.pm,v 1.32 2001/11/08 03:37:58 fukachan Exp $
#

package FML::Process::Switch;

use strict;
use Carp;
use vars qw($debug);


=head1 NAME

FML::Process::Switch - dispatch the suitable library

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
the corresponding library with the arguments.
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
#    Arguments: $main_cf_file
#               /etc/fml/main.cf in typical case.
# Side Effects: none
# Return Value: the same as FML::Process::Flow::ProcessStart()
sub main::Bootstrap2
{
    my ($main_cf_file)    = @_;
    my @argv              = @ARGV; # save the original argument vector
    my @cf                = ();
    my %options           = ();
    my $ml_home_dir       = ''; # e.g. /var/spool/ml/elena

    use File::Basename;
    my $myname            = basename($0); # inspect my name from $0

    # 0.1
    print STDERR "\nsetuid is not set $< != $>\n\n" if $< != $>;
    print STDERR "\nsetgid is not set $( != $)\n\n" if $( ne $);

    # 0.2
    if ($0 =~ /loader/) {
	print "ARGV: @ARGV\n";
    }

    # 1.1 parse command line options (preliminary)
    use Getopt::Long;
    GetOptions(\%options, _module_specific_options($myname));

    # 2.1 analyze main.cf and get the result in $main_cf
    use Standalone;
    $main_cf_file = $options{'c'} || $main_cf_file;
    my $main_cf   = Standalone::load_cf($main_cf_file, $options{'params'});

    # 2.2 parse @ARGV and get a list of configuration files
    #     XXX $main_cf{ ml_home_dir } (e.g. /var/spool/ml/elena) is defined
    #         if possible.
    #     a) resolve $ml_name (e.g. expand "elena" to "/var/spool/ml/elena")
    #     b) but we need special treatment in some cases e.g. makefml
    my $cf = _parse_argv($myname, $main_cf);

    # 2.3 prepare @$cf
    #     XXX hmm, .. '/etc/fml/site_default_config.cf' is good ???
    unshift(@$cf, '/etc/fml/site_default_config.cf');
    unshift(@$cf, $main_cf->{ default_config });

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
    my $args = {
	fml_version    => $main_cf->{ fml_version },
	
	myname         => $myname,
	program_name   => $myname,
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
    eval q{
      FML::Process::Flow::ProcessStart($obj, $args);
    };
    if ($@) {
	my $reason = $@;
	if ($obj->can('help')) { eval $obj->help();};

	if ($ENV{'debug'} || 
	    defined( $main_cf->{ debug } ) || 
	    defined $options{debug}) {
	    croak($reason);
	}
	else {
	    $reason =~ s/[\n\s]*at.*$//m;
	    croak($reason);
	}
    }
}


# Descriptions: analyze argument vector
#    Arguments: $main_cf_file_name
# Side Effects: none
# Return Value: ARRAY REFERENCE (a list of config.cf's)
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


sub _usual_parse_argv
{
    my ($myname, $main_cf) = @_;
    my $ml_home_prefix = $main_cf->{ ml_home_prefix };
    my $ml_home_dir    = '';
    my $found_cf       = 0;
    my @cf             = ();

    # "elena" is translated to "/var/spool/ml/elena"
    for (@ARGV) {
	# 1. for the first time
	#   a) speculate "/var/spool/ml/$_" looks a $ml_home_dir ?
	unless ($found_cf) {
	    my $x = "$ml_home_prefix/$_";
	    if (-d $x && -f "$x/config.cf") {
		$found_cf = 1;
		$ml_home_dir = $x;
		push(@cf, "$x/config.cf"); 
	    }
	}

	# 2. /var/spool/ml/elena looks a $ml_home_dir ?
	if (-d $_) {
	    $ml_home_dir = $_;
	    if (-f "$_/config.cf") {
		push(@cf, "$_/config.cf");
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


sub _makefml_parse_argv
{
    my ($myname, $main_cf) = @_;
    my $ml_home_prefix = $main_cf->{ ml_home_prefix };

    # makefml specific syntax.
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
    $main_cf->{ ml_home_dir } = "$ml_home_prefix/$ml_name";

    # config.cf
    my $cf = "$ml_home_prefix/$ml_name/config.cf";
    my @cf = ($cf);

    \@cf;
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
#    Arguments: $args
#               XXX non OO interface
# Side Effects: process switching :-)
#               ProcessSwtich() is exported to main:: Name Space.
# Return Value: package name
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
#    Arguments: $myname (determined by $0)
# Side Effects: none
# Return Value: getopt parameters
sub _module_specific_options
{
    my ($myname) = @_;

    if ($myname eq 'fml.pl' || 
	$myname eq 'loader' ) { 
	return qw(ctladdr! debug! params=s -c=s);
    }
    elsif ($myname eq 'fmlthread'|| $myname eq 'fmlthread.cgi') {
	return qw(debug! 
		  article_id_max=i
		  spool_dir=s
		  base_url=s
		  reverse!
		  params=s -f=s -c=s);
    }
    elsif ($myname eq 'fmlconf') {
	return qw(debug! params=s -c=s n!);
    }
    elsif ($myname eq 'fmldoc') {
	# perldoc [-h] [-v] [-t] [-u] [-m] [-l]
	return qw(debug! params=s -c=s v! t! u! m! l!);
    }
    elsif ($myname eq 'makefml') {
	return qw(debug! params=s -c=s);	
    }
    elsif ($myname eq 'makefml.cgi') {
	return qw(debug!);
    }
    elsif ($myname eq 'fmlsch.cgi') {
	return qw(debug!);
    }
    elsif ($myname eq 'fmlsch') {
	return qw(debug! -D=s -F=s -m=s a!);
    }
    elsif ($myname eq 'fmlhtmlify') {
	return qw(debug! -I=s);
    }
    else {
	croak "no such program $myname.\n";
    }
}


# Descriptions: this program ($0) requires ML name always or not?
#    Arguments: $myname ($0)
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
    else {
	return 1;
    }
}


# Descriptions: determine package we need and require() it if needed.
#    Arguments: $args
#               XXX non OO interface
# Side Effects: none
# Return Value: FML::Process::SOMETHING module name
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
    elsif ($name eq 'fmlconf' || $name eq 'makefml') {
	$pkg = 'FML::Process::Configure';
    }
    elsif ($name eq 'fmlthread.cgi') {
	$pkg = 'FML::CGI::ThreadTrack';
    }
    elsif ($name eq 'fmlthread') {
	$pkg = 'FML::Process::ThreadTrack';
    }
    elsif ($name eq 'mead') {
	$pkg = 'FML::Process::MailErrorAnalyzer';
    }
    elsif ($name eq 'qmail-ext') {
	$pkg = 'FML::Process::QMail';
    }
    elsif ($name eq 'makefml.cgi') {
	$pkg = 'FML::CGI::Configure';
    }
    elsif ($name eq 'fmlsch') {
	$pkg = 'FML::Process::Scheduler';
    }
    elsif ($name eq 'fmlsch.cgi') {
	$pkg = 'FML::CGI::Scheduler';
    }
    elsif ($name eq 'fmlhtmlify') {
	$pkg = 'FML::Process::HTMLify';
    }
    else {
	return '';
    }

    return $pkg;
}


=head1 SEE ALSO

L<FML::Process::Distribute>,
L<FML::Process::Command>,
L<FML::Process::ListServer>,
L<FML::Process::Configure>,
L<FML::Process::ThreadTrack>,
L<FML::Process::MailErrorAnalyzer>

=cut

1;
