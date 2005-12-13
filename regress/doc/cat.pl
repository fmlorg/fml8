#!/usr/bin/env perl
#-*- perl -*-
#
# $FML: check.pl,v 1.1.1.1 2005/09/30 13:30:31 fukachan Exp $
#

use strict;
use Carp;
use vars qw(%entity %file %used %file_in_dir);

my $entity = "include/chapters.ent";
parse($entity, 0);
parse("book.sgml", 1);

exit 0;

sub parse
{
    my ($file, $is_print) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $buf;
      LINE:
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
		    parse($_file, $is_print);
		    next LINE;
		}
	    }

	    if ($is_print) {
		print $buf;
	    }
	}
	$rh->close();
    }
    else {
	croak("cannot open \"$file\"\n");
    }
}


