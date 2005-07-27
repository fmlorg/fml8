#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: distdir2url.pl,v 1.3 2002/04/01 23:41:23 fukachan Exp $
#

use strict;
use Carp;

my $Module;

HEADER();
Show();
FOOTER();


exit 0;


sub Show
{
    print "<CENTER>\n";
    print "<TABLE>\n";

    foreach my $pathname (<*>) {
	next if $pathname =~ /^\__template/;
	next if $pathname =~ /^\@/;
	next if $pathname =~ /\~$/;
	next if $pathname =~ /pod$/;
	next if $pathname eq 'CVS';
	next if $pathname =~ /^index/;
	next if $pathname =~ /^00_/;
	next if $pathname eq 'Makefile';

	print "<TR>\n";
	print "<TD> $pathname \n";

	for my $fn ("README", "INSTALL", "MANIFEST",
		    "00readme", "00install", "00manifest") {
	    print "<TD>";
	    if (-f "$pathname/$fn") {
		print "<A HREF=\"$pathname/$fn\">$fn</A>\n";
	    }
	    print "\n";
	}
    }

    print "</TABLE>\n";
    print "</CENTER>\n";
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
