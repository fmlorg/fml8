#!/usr/bin/perl -s -I lib/
##
##
##
## Copyright (c) 1999, Vipul Ved Prakash.  All rights reserved.
## This code is free software; you can redistribute it and/or modify
## it under the same terms as Perl itself.
##
## $Id$

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Crypt::TripleDES;
$loaded = 1;
print "ok 1\n";

