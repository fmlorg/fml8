#!/usr/bin/env perl
#-*- perl -*-
#
# $FML$
#

use strict;
use Carp;
use vars qw($debug $buf $in_q $in_a $question);

 LINE:
    while ($buf = <>) {
	if ($buf =~ /<question>/)   { $in_q = 1; next LINE;}
	if ($buf =~ /<\/question>/) { $in_q = 0; next LINE;}
	if ($buf =~ /<answer>/)     { $in_a = 1; next LINE;}
	if ($buf =~ /<\/answer>/)   { $in_a = 0; undef $question; next LINE;}
	if ($buf =~ /^\s*\</) {
	    next LINE;
	}
 
	if ($in_q) {
	    $question .= $buf;
	    next LINE;
	}

	if ($in_a) {
	    if ($buf =~ /Ì¤¼ÂÁõ/) {
		print "[TODO] ";
		print $question;
	    }
	}
    }

exit 0;
