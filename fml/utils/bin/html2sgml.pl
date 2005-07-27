#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: html2sgml.pl,v 1.3 2002/04/01 23:41:23 fukachan Exp $
#

use strict;
use Carp;
use vars qw($TR);
use FileHandle;

my $para = '';
my $hr   = 0;
my $tr   = 0;
my $listitem = 0;

for my $file (@ARGV) {
    my $rh;

    my $tmpf = "/tmp/html2sgml.$$";
    my $wh = new FileHandle "> $tmpf";
    convert($file, $rh, $wh);
    $wh->close;

    my $rh = new FileHandle $tmpf;
    fix_output($rh);

    unlink $tmpf;
}

exit 0;


sub convert
{
    my ($file, $rh, $wh) = @_;

    my $fh = new FileHandle $file;

    while (<$fh>) {
	# <P>
	if (m@<P>@i) {
	    print $wh  "<para>\n";
	    $para = 1;
	    next;
	}

	if (/^\s*$/ && $para) {
	    print $wh  "\t" if $para eq 'tab';
	    print $wh  "</para>\n\n";
	    $para = 0;
	}

	# HR
	if (m@<HR>@i) {
	    print $wh  "</sect1>\n" if $hr;
	    s@<HR>@<sect1>@gi;
	    $hr = 1;
	}

	# A
	s@<A\s*HREF=@\n<ulink url=@gi;
	s@</A>@\n</ulink>\n@gi;

	# PRE
	s@<PRE>@<screen>@gi;
	s@</PRE>@</screen>@gi;

	# UL
	s@<UL>@<itemizedlist>@gi;
	s@</UL>@</itemizedlist>@gi;

	if (m@<LI>@i) {
	    print $wh  "\t" if $para eq 'tab' && $listitem;
	    print $wh  "\t</listitem>\n\n" if $listitem;
	    s@<LI>@<listitem>\n\t<para>\n\t@gi;
	    $para = "tab";
	    $listitem = 1;
	}

	if (m@</itemizedlist>@) {
	    print $wh  "\t" if $para eq 'tab' && $listitem;;
	    print $wh  "\t</listitem>\n\n" if $listitem;
	    $listitem = 0;
	}


	# BR
	s@<HR>@@gi;
	s@<BR>@@gi;
	s@<EM>@@gi;
	s@</EM>@@gi;
	s@<B>@@gi;
	s@</B>@@gi;
	s@<I>@@gi;
	s@</I>@@gi;


	# TABLE
	s@<TABLE.*>@<table>\n <tgroup cols=2>\n@gi;
	s@</TABLE>@\n </tgroup>\n</table>@gi;
	if (m@<TR>@) {
	    $TR = $TR ? 'tbody' : 'thead';
	    $tr++;
	    s@<TR>@<$TR>\n\t<row>@gi;
	}

	if (m@<TD>@) {
	    s@<TD>@<entry>@;
	    s@$@\n\t</entry>@;
	}

	if ($tr && /^\s*$/) {
	    print $wh  "\t</row>\n";
	    print $wh  "   </${TR}>\n";
	    $tr = 0;
	}

	print $wh $_;
    }
}


sub fix_output
{
    my ($rh) = @_;
    my $buf;

    while (<$rh>) {
	$buf .= $_;
    }

    $buf =~ s@</tbody>[\s\n]*<tbody>@\n@g;

    print $buf;
}
