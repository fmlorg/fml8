#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Switch.pm,v 1.94 2003/09/13 06:14:38 fukachan Exp $
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

=head2 main::Bootstrap2()

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
    # XXX valid use of STDERR
    print STDERR "\nsetuid is not set $< != $>\n\n" if $< != $>;
    print STDERR "\nsetgid is not set $( != $)\n\n" if $( ne $);

    # 0.2
    if ($myname eq 'loader') {
	print "ARGV: @ARGV\n";
    }

    # 0.3 overload main.cf (defaults/$version/main.cf + main.cf)
    #     to inherit $default_* variables defined later.
    #     installer should merget the changes except for $default_*.
    $main_cf = _overload_main_cf($main_cf);

    # 1.0 $main_cf is already o.k. here.
    # 1.1 parse command line options (preliminary)
    {
	my $options = _module_specific_options($main_cf, $myname);

	if (@$options) {
	    eval q{
		use Getopt::Long;
		GetOptions(\%options, @$options);
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
	fml_version      => $main_cf->{ fml_version },

	myname           => $myname,
	program_name     => $myname,
	program_fullname => $ENV{ 'SCRIPT_FILENAME' } || $0,

	#    XXX CAN WE MOVE PARSER TO Process::{Kernel,CGI::Kernel} ?
	#    XXX ml_name, ml_domain, ml_home_prefix, ml_home_dir
	# ml_home_prefix => $ml_home_prefix,
	# ml_home_dir    => $main_cf->{ ml_home_dir },

	cf_list          => $cf,       # site_default + default
	options          => \%options, # options parsed by getopt()

	argv             => \@argv,    # pass the original @ARGV
	ARGV             => \@ARGV,    # @ARGV after getopts()

	main_cf          => $main_cf,

	# options
	need_ml_name     => 0,         # defined in _module_we_use()
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


=head2 ProcessSwitch($args)

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
	need_ml_name   => _ml_name_is_required($args, $myname),
    };

    # get the object. The suitable module is speculcated by $0.
    my $obj = ProcessSwitch($args);

    # start the process.
    FML::Process::Flow::ProcessStart($obj, $args);

=cut


# Descriptions: top level process switch
#               emulates "use $package" but $package is dynamically
#               determined by e.g. $0.
#    Arguments: STR($myname) HASH_REF($args)
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


# Descriptions: read defaults/$version/main.cf if exists and merge it
#               with the specified $main_cf.
#    Arguments: HASH_REF($main_cf)
# Side Effects: none
# Return Value: HASH_REF
sub _overload_main_cf
{
    my ($main_cf) = @_;
    my $new_main_cf = {};
    my $config_dir  = $main_cf->{ default_config_dir };

    use File::Spec;
    my $default_main_cf = File::Spec->catfile($config_dir, 'main.cf');
    if (-f $default_main_cf) {
	my ($k, $v);

	use FML::Config::Tiny;
	my $tinyconfig = new FML::Config::Tiny;
	$new_main_cf = $tinyconfig->read($default_main_cf);

	# overwrittern by the specified $main_cf (e.g. /etc/fml/main.cf)
	while (($k, $v) = each %$main_cf) {
	    $new_main_cf->{ $k } = $v;
	}

	# variable expansion by the function in libexec/loader.
	main::loader_expand_variables( $new_main_cf );
	$main_cf = $new_main_cf;
    }

    return $main_cf;
}


# Descriptions: return the suitable getopt options
#    Arguments: HASH_REF($main_cf) STR($myname)
# Side Effects: none
# Return Value: ARRAY (getopt parameters)
sub _module_specific_options
{
    my ($main_cf, $myname) = @_;
    my $modules = $main_cf->{ default_command_line_option_config };

    use FileHandle;
    my $fh = new FileHandle $modules;
    if (defined $fh) {
	my $buf;
      LINE:
	while ($buf = <$fh>) {
	    next LINE if $buf =~ /^\#/o;
	    chomp $buf;

	    if (defined $buf && $buf) {
		my ($program, @opts) = split(/\s+/, $buf);
		if ($program eq $myname) {
		    return( \@opts || [] );
		    last LINE;
		}
	    }
	}
	$fh->close();
    }
    else {
	croak("cannot open comman_line_options config");
    }

    croak "no such program $myname.\n";
}


# Descriptions: this program ($0) requires ML name always or not?
#    Arguments: HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 (require ml name always) or 0)
sub _ml_name_is_required
{
    my ($args) = @_;
    my $opt = $args->{ module_info }->{ options } || '';

    return($opt =~ /\$ml/o ? 1 : 0);
}


# Descriptions: determine package we need and require() it if needed.
#    Arguments: HASH_REF($args)
# Side Effects: none
# Return Value: STR(FML::Process::SOMETHING module name)
sub _module_we_use
{
    my ($args)   = @_;
    my $main_cf  = $args->{ main_cf };
    my $name     = $args->{ myname };
    my $modules  = $main_cf->{ default_module_config };
    my $pkg      = undef;
    my $pkgopts  = undef;
    my $fullname = $args->{ program_fullname };

    if (defined $args->{ options }->{ ctladdr } &&
	$args->{ options }->{ ctladdr }) {
	$name .= "__--ctladdr";
    }

    use FileHandle;
    my $fh = new FileHandle $modules;
    if (defined $fh) {
	my $buf;
      LINE:
	while ($buf = <$fh>) {
	    next LINE if $buf =~ /^\#/o;
	    chomp $buf;

	    if (defined $buf && $buf) {
		my ($program, $class, $opts) = split(/\s+/, $buf, 3);
		if (_program_match($program, $name, $fullname)) {
		    $pkg     = $class;
		    $pkgopts = $opts;
		    last LINE;
		}
	    }
	}
	$fh->close();
    }
    else {
	croak("cannot open module config");
    }

    print STDERR "module = $pkg (for $0)\n" if $debug;

    # saved info
    $args->{ module_info } = {
	class   => $pkg,
	options => $pkgopts,
    };
    $args->{ need_ml_name } = _ml_name_is_required($args);

    return $pkg;
}


# Descriptions: compare $program (entry in etc/modules) and $0.
#               $program   = entry in etc/modules
#               $name      = basename($0)
#               $fullname  = $0
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _program_match
{
    my ($program, $name, $fullname) = @_;

    if ($name =~ /^[\w\d\.]+$/o) {
	if ($program eq $name) {
	    return 1;
	}
	else {
	    return _program_subdir_match($program, $name, $fullname);
	}
    }    
    else {
	return _program_subdir_match($program, $name, $fullname);
    }

    return 0;
}


# Descriptions: compare $program (entry in etc/modules) and $0.
#               $program   = entry in etc/modules
#               $name      = basename($0)
#               $fullname  = $0
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: NUM(1 or 0)
sub _program_subdir_match
{
    my ($program, $name, $fullname) = @_;
    my (@n) = split(/\//, $program);

    use File::Spec;
    my ($v, $d, $n) = File::Spec->splitpath($fullname);
    my (@p)         = File::Spec->splitdir(File::Spec->catfile($d, $n));

    # @n is shorter than @p;
    my $count = 0;
    @n = reverse @n;
    @p = reverse @p;
    for (my $i = 0; $i <= $#n; $i++) {
	if ($n[$i] eq $p[$i]) {
	    $count++;
	}
	elsif ($n[$i] eq '*') {
	    $count++;
	}
    }

    if ($count == ($#n + 1)) {
	return 1;
    }

    return 0;
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

Copyright (C) 2001,2002,2003 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

FML::Process::Switch first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
