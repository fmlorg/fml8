#!/usr/local/bin/perl -w
#------------------------------------------
# Test symrev method
#------------------------------------------
use strict;
use Rcs;

Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");

my %symbols = $obj->symbols;
my $sym;
foreach $sym (keys %symbols) {
    my $rev = $symbols{$sym};
    print "Symbol : Revision = $sym : $rev\n";
}

my @syms = keys %symbols;
print "@syms\n";
