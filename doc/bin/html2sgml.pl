#!/usr/local/bin/perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: __template.pm,v 1.5 2001/04/03 09:45:39 fukachan Exp $
#

use strict;
use Carp;

my $para = '';
my $hr   = 0;
my $listitem = 0;

while (<>) {
    # <P>
    if (m@<P>@i) { 
	print "<para>\n";
	$para = 1;
	next;
    }

    if (/^\s*$/ && $para) {
	print "\t" if $para eq 'tab';
	print "</para>\n\n";
	$para = 0;
    }

    # HR
    if (m@<HR>@i) {
	print "</sect1>\n" if $hr;
	s@<HR>@<sect1>@gi;
	$hr = 1;
    }

    # A
    s@<A\s*HREF=@<ulink url=@gi;
    s@</A>@</ulink>@gi;

    # PRE
    s@<PRE>@<programlisting>@gi;
    s@</PRE>@</programlisting>@gi;

    # UL
    s@<UL>@<itemizedlist>@gi;
    s@</UL>@</itemizedlist>@gi;

    if (m@<LI>@i) {
	print "\t" if $para eq 'tab' && $listitem;
	print "\t</listitem>\n\n" if $listitem;
	s@<LI>@<listitem>\n\t<para>\n\t@gi;
	$para = "tab";
	$listitem = 1;
    }

    if (m@</itemizedlist>@) {
	print "\t" if $para eq 'tab' && $listitem;;
	print "\t</listitem>\n\n" if $listitem;
	$listitem = 0;
    }


    # BR
    s@<BR>@<newline>@gi;

    print;
}

exit 0;
