#!/usr/local/bin/perl -w

use strict;
use lib '.';
use Rcs;

my $p = new Rcs();
$p->workdir("foo");

my $n = new Rcs();
$n->workdir("bar");

print $p->workdir, "\n";
print $n->workdir, "\n";
