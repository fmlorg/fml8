#!/usr/local/bin/perl -w

use strict;
use lib '.';
use Rcs;

Rcs->workdir("foo");

my $p = new Rcs();
my $n = new Rcs();

Rcs->workdir("bar");

print $p->workdir, "\n";
print $n->workdir, "\n";
