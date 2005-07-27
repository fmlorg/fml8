#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: text2html.pl,v 1.3 2002/04/01 23:41:24 fukachan Exp $
#

use strict;
use Carp;


&HEADER;
print "<PRE>\n";
while (<>) { print $_;}
print "</PRE>\n";
&FOOTER;

1;


sub HEADER
{

print <<"_EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE>
$ARGV[0]
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
