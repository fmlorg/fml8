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

Init();
HEADER();
Show();
FOOTER();

exit 0;


sub Init
{
    my $pwd = `pwd`;
    chop($pwd);
    $pwd =~ s@^.*fml/lib/@@;
    $pwd =~ s@^.*cpan/dist@@;
    $pwd =~ s@^.*cpan/lib/@@;
    $ModulePrefix = $pwd;
    $ModulePrefix =~ s@/@::@g;
    $Module       = $pwd . "::*";
}


sub Show
{
    print "<P> $ModulePrefix classes \n<BR>\n";
    print "<UL>\n";

    my $pathname = '';

    foreach $pathname (<*>) {
	next if $pathname =~ /^\@/;
	next if $pathname =~ /\~$/;
	next if $pathname eq 'CVS';
	next if $pathname =~ /^index/;
	next if $pathname eq 'Makefile';

	my $module = $pathname;
	if ($module =~ /pm/) {
	    $module = $ModulePrefix. "::". $pathname;
	    $module =~ s/\.pm$//;
	}

	if (-d $pathname) {
	    print "\t<LI> ";
	    
	    if (-f "$pathname/index.ja.html") {
		print " <A HREF=$pathname/index.ja.html>";
		print "${module}::*</A>\n";
	    }
	    else {
		if (-f "$pathname/README") {
		    print " <A HREF=$pathname/README>README</A>\n";
		}

		if ( -f "$pathname/INSTALL") {
		    print " <A HREF=$pathname/INSTALL>INSTALL</A>\n";
		}

		print STDERR "Error: *** fail to convert $pathname ***\n";
	    }
	}
	else {
	    print "\t<LI> ";
	    print " <A HREF=\"$pathname\">$module</A>\n";
	}
    }

    print "</UL>\n";
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
