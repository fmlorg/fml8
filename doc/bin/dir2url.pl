#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

use strict;
use Carp;

my $Module;
my $ModulePrefix;
my $TableMode = 1;

Init();
HEADER();
Show();
FOOTER();

exit 0;


sub Init
{
    my $pwd = `pwd`;
    chop($pwd);
    $pwd =~ s@^.*fml/lib@@;
    $pwd =~ s@^.*cpan/dist@@;
    $pwd =~ s@^.*cpan/lib@@;
    $pwd =~ s@^/@@;
    $ModulePrefix = $pwd;
    $ModulePrefix =~ s@/@::@g;
    $Module       = $pwd . "::*";
}


sub Show
{
    print "<CENTER><EM>$ModulePrefix class modules</EM></CENTER>\n<HR>\n";
    print ($TableMode ? "<TABLE BRODER=4>\n" : "<UL>\n");
    
    my $pathname = '';
    my $doc      = '';

    unlink ".cvsignore" if -f ".cvsignore";

    foreach $pathname (<*>) {
	next if $pathname =~ /^\__template/;
	next if $pathname =~ /^\@/;
	next if $pathname =~ /\~$/;
	next if $pathname =~ /pod$/;
	next if $pathname eq 'CVS';
	next if $pathname eq 't'; # test directory
	next if $pathname =~ /^index/;
	next if $pathname eq 'Makefile';

	my $module = $pathname;

	# ignore module.txt file 
	# which is generated from module.pm automatically
	if ($module =~ /txt$/) { 
	    my $x = $module;
	    $x    =~ s/txt$/pm/; 
	    next if -f $x;
	}

	if ($module =~ /\.pm$/) {
	    $module = $ModulePrefix. "::". $pathname;
	    $module =~ s/\.pm$//;

	    if (-f $pathname) {
		$doc = '@'.$pathname;
		$doc =~ s/pm$/txt/;
		print STDERR "\tpod2text $pathname > $doc\n";
		system "pod2text $pathname > $doc";
		system "echo $doc >> .cvsignore";
	    }
	}

	if (-d $pathname) {
	    print ($TableMode ? "<TR>\n" : "<LI>\n");
	    print "<TD>\n" if $TableMode;
	    
	    if (-f "$pathname/index.ja.html") {
		print " <A HREF=$pathname/index.ja.html>";

		if ($ModulePrefix) {
		    print "${ModulePrefix}::${module}::* class</A>\n";
		}
		else {
		    print "${module}::*</A>\n";
		}
	    }
	    else {
		if (-f "$pathname/README") {
		    print " <A HREF=$pathname/README>README</A>\n";
		}

		if ( -f "$pathname/INSTALL") {
		    print " <A HREF=$pathname/INSTALL>INSTALL</A>\n";
		}

		print STDERR "Error: *** fail to convert $pathname ***\n";
		print "${pathname}/\n";
	    }
	}
	else {
	    print ($TableMode ? "<TR>\n" : "<LI>\n");
	    print "<TD>\n" if $TableMode;
	    print " $module ";

	    print "<TD>\n" if $TableMode;
	    print "<A HREF=\"$pathname\">[source]</A>\n";

	    print "<TD>\n" if $TableMode;
	    print "<A HREF=\"$doc\">[doc]</A>\n" if -f $doc;
	}
    }

    print ($TableMode ? "</TABLE>\n" : "</UL>\n");
}



sub HEADER 
{

print <<"_EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE>
$Module classes
</TITLE>
<META http-equiv="Content-Type"
	content="text/html; charset=EUC-JP">
</HEAD>

<BODY BGCOLOR="#E6E6FA">
_EOF

}


sub FOOTER
{

print <<'_EOF';
</BODY>
</HTML>
_EOF

}


1;
