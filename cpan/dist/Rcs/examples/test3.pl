#!/usr/local/bin/perl -w

use strict;
use lib '.';
use Rcs;

my $p = new Rcs();
my $n = new Rcs();

my $m = new Rcs();
$m->workdir("foo");

Rcs->workdir("bar");

print $p->workdir, "\n";
print $n->workdir, "\n";
print $m->workdir, "\n";
