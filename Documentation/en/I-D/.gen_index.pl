#!/usr/bin/env perl
#
# $FML$
#

use strict;
use Carp;

my $categories = {};
my $list       = {};


for my $file (sort _sort @ARGV) {
    my $category = _category($file);

    $list->{ $category } = [] unless defined $list->{ $category };
    my $array = $list->{ $category };
    push(@$array, $file);
}


print "<UL>\n";
for my $category ('a' .. 'z') {
    next unless defined $categories->{ $category };

    {
	my $categories = $categories->{ $category }; 
	my $c = $category; $c =~ tr/a-z/A-Z/;
	print "<LI> $c ($categories)\n";
	print "<UL>";
    }

    my $array = $list->{ $category };
    for my $file (@$array) {
	print "   <LI>\n";
	print "   <A HREF=\"$file\">\n   $file\n   </A>\n";
	_read($file);
	print "\n\n";
    }

    print "</UL>";
}
print "</UL>\n";


exit 0;


sub _category
{
    my ($file) = @_;
    my (@name) = split(/\-/, $file);
    my $theme  = $name[2];

    $theme =~ tr/A-Z/a-z/;
    if ($theme =~ /^(.)/) {
	my $c = $1;
	unless ($categories->{ $c } =~ /$theme/i) {
	    $categories->{ $c } .= " " if defined $categories->{ $c };
	    $categories->{ $c } .= $theme;
	} 

	return $c;
    }
}


sub _sort
{
    my $xa = $a;
    my $xb = $b;

    $xa =~ tr/A-Z/a-z/;
    $xb =~ tr/A-Z/a-z/;
    my (@xa) = split(/\-/, $xa);
    my (@xb) = split(/\-/, $xb);

    $xa[2] cmp $xb[2];
}


sub _read
{
    my ($file) = @_;
    my $is_need_new_rfc = 0;

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	while (<$fh>) {
	    next if /^\s*$/;
	    next if /\@/;
	    next if /^INTERNET-DRAFT/;
	    next if /^Network Working Group/;
	    next if /^Internet Draft: /;
	    next if /^Document:/;
	    next if /^Expires /;
	    next if /^File Name:/;
	    next if /^Draft Author/;
	    next if /\[Page \d+\]/i;

	    if (/^\s*Status of this \S+/i ||
		/^\s*This document is an Internet-Draft./) {
		last;
	    }

	    if (/^This  document has been replaced by/) {
		print "\t", $_;
		last;
	    }

	    if (/^(This Internet-Draft has been deleted.)/i) {
		print "\t", $1, "\n";
		last;
	    }

	    if ($is_need_new_rfc && /rfc\s*(\d+)/i) {
		my $n = $1;
		print "   ";
		print "<A HREF=\"../rfc/rfc$n.txt\">";
		print "RFC$n";
		print "</A>\n";
		last;
	    }

	    if (/^\s*A new Request for Comments is now available/i) {
		$is_need_new_rfc = 1;
	    }

	    print "\t", $_;
	}
	close($fh);
    }
}
