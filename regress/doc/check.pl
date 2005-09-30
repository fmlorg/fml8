#!/usr/bin/env perl
#-*- perl -*-
#
# $FML$
#

use strict;
use Carp;
use vars qw(%entity %file %used %file_in_dir);

my $entity = "include/chapters.ent";
parse($entity);
parse("book.sgml");
files();
compare();

exit 0;

sub parse
{
    my ($file) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $buf;
	while ($buf = <$rh>) {
	    # <!entity chapter.download SYSTEM "install/download.sgml">
	    if ($buf =~ /<\!entity\s+(\S+)\s+SYSTEM\s+"(\S+)">/) {
		$entity{ $1 } = $2;
		$file{ $2 }   = $1;
	    }

	    # usual file
	    if ($buf =~ /\&(\S+);/) {
		$used{ $1 } = 1;
		my $_file = $entity{ $1 } || '';
		if ($_file && -f $_file) {
		    parse($_file);
		}
	    }
	}
	$rh->close();
    }
    else {
	croak("cannot open \"$file\"\n");
    }
}


sub files
{
    for my $f (<*.sgml>, <*/*.sgml>) {
	$file_in_dir{ $f } = 1;
    }
}


sub compare
{
    print "\n[ENTITY]\n";
    for my $k (keys %entity) {
	unless ($used{ $k }) {
	    print "   NOT USED: $k\n";
	}
	else {
	    print "       USED: $k\n" if 0;
	}
    }

    print "\n[FILE]\n";
  FILE:
    for my $f (keys %file_in_dir) {
	next FILE if $f eq 'book.sgml';

	unless ($file{ $f }) {
	    print "NOT DEFINED: $f\n";
	}
	else {
	    print "    DEFINED: $f\n" if 0;
	}
    }
}
