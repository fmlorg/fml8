#!/usr/local/bin/perl -w
#------------------------------------------
# Access comments hash
#------------------------------------------
use strict;
use lib '.';
use Rcs;

Rcs->bindir('/usr/bin');
my $obj = Rcs->new;

$obj->rcsdir("./project/RCS");
$obj->workdir("./project/src");
$obj->file("Rcs.pm");

my %comments = $obj->comments;
my $revision;
foreach $revision (sort keys %comments) {
    #my $comments = $comments{$revision} ? $comments{$revision} : 'GGG';
    my $comments = $comments{$revision};
    print "======\n";
    print "Revision: $revision\n";
    print "$comments###\n";
}
