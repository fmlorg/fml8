#!/usr/local/bin/perl -w
#------------------------------------------
# Test symrev method
#------------------------------------------
use strict;
use Rcs;

#Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("testfile");
(my $symbol = shift) or die "Usage: $0 symbol\n";

# scalar mode
print "Scalar mode:\n";
my $revision = $obj->symrev($symbol);
print "Symbol : Revision = $symbol : $revision\n";


# list mode
print "\nList mode:\n";
my %symbols = $obj->symrev($symbol);
foreach (keys %symbols) {
    print "Symbol : Revision = $_ : $symbols{$_}\n";
}
