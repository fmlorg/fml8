#!/usr/bin/env perl
#
# $FML: check_pcb.pl,v 1.1 2003/10/29 14:50:55 fukachan Exp $
#

use strict;
use Carp;
use FileHandle;

my $in_function   = 0; 
my $found         = 0;
my $use           = '';
my $function      = '';
my %function_def  = ();
my %function_call = ();
my %function_args = ();
my $re;

init();
_print_patch_pre();

while (<>) {
    if (/^sub\s*(\S+)/) {
	$function    = $1;
	$in_function = 1;
	next;
    }

    if (/^\}/) {
	if ($found) {
	    print "\n";
	    if ($use) {
	        print "   \# $ARGV $function:\n";
		print "   \# \t\$args is defined and referred.\n";
		$function_args{ "$function $ARGV" } = 1;
	    }
	    else {
		if ($function =~ /^($re)$/) {
		    if (0) {
			print "   \# $ARGV $function:\n";
			print "   \# \t\tOK> USE of \$args is o.k.\n";
		    }
		}
		else {
		    print "   \# $ARGV $function:\n";
		    print "   \# \t***NOT USED ***: ";
		    print " \$args is defined but NOT USED.\n";
		    $function_args{ "$function $ARGV" } = 0;
		}
	    }

	    unless ($use) {
		unless ($function =~ /^($re)$/) {
		    _print_patch($ARGV, $function);
		}
	    }
	    else {
		for (split(/\n/, $use)) {
		    print "   \#   $_\n";
		    if (/cgi_menu|run_cgi|resolv_/) {
			unless ($function =~ /^($re)$/) {
			    _print_patch($ARGV, $function);
			}
		    }
		}
	    }
	    print "\n";
	}

	$in_function = 0;
	$found       = 0;
	$use         = '';
	$function    = '';

	next;
    }

    if ($in_function) {
	if (/my.*=.*\@_/) { 
	    my $a = $function_def{ $function };
	    $a ||= [];
	    s/\s+/ /g;
	    s/\s*$//g;
	    s/^\s*//g;
	    push(@$a, "DEF($ARGV $.)");
	    push(@$a, "$function { $_ }");
	    push(@$a, "");
	    $function_def{ $function } = $a;
	}

	if (/my.*(\$curproc|\$self).*\$args.*=.*\@_/) { 
	    $found = 1;
	    next;
	}

	next if /new FML::Process::Kernel/;

	if ($found && /\$args/) {
	    $use .= $_;
	}

        # cross checks
	if (/->([\w\d_]+)\(.*\$args/) {
	    my $f = $1;
	    chomp;
	    if ($f !~ /^($re)$/) {
		$function_call{ "$f $ARGV $." } = $f;
	    }
	}
    }
}

_print_patch_post();

_print_summary();

exit 0;


sub _print_patch_pre
{
    print "while (<>) {\n";
}


sub _print_patch_post
{
    print "   print;\n}\n";
}


sub _print_patch
{
    my ($file, $function) = @_;

    print "   if (\$ARGV eq \"$file\") {\n";
    print "     if (/^sub $function/) { \$in=1;}\n";
    print "     if (/^\\}/)           { \$in=0;}\n";
    print "     if (\$in) {\n";
    print "\ts/\\\(\\\$args\\\)/\(\)/g;\n";
    print "\ts/\\\(\\\$args,/\(/g;\n";
    print "\ts/,\\s*\\\$args\\\)/\)/g;\n";
    print "\ts/,\\s*\\\$args,/,/g;\n";
    print "     }\n";
    print "   }\n";
}


sub _print_summary
{
    # summary
    for my $fn (sort keys %function_call) {
	my ($xf, $xfile, $xline) = split(/\s+/, $fn);
	my $f   = $function_call{ $fn };
	my $use = $function_args{ "$xf $xfile" };

	next if $f =~ /^($re)$/;

	if (defined $function_def{ $f }) {
	    my $a = $function_def{ $f };
	    print STDERR "\n   CALL($fn):\n\t";
	    print STDERR join("\n\t", @$a);
	    print STDERR "\n";
	}
	else {
	    print STDERR "\n   CALL($fn):\n";
	    print STDERR "\tUNDEF ?\n";
	}

	print STDERR $use ? "\t\$args USED" : "   !!! \t\$args NOT USED\n";
	print STDERR "\n";
    }
}


sub init
{
    # valid method list.
    my @re = qw(new 
		run
		finish
		help
		prepare
		verify_request
		_faker_\S+
		_finalize_stderr_channel
		_distribute
		_makefml
		_trap_help
		);

    $re = join("|", @re);
}
