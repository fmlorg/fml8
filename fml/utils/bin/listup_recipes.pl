#!/usr/bin/env perl
#-*- perl -*-
#
# $FML: check.pl,v 1.1.1.1 2005/09/30 13:30:31 fukachan Exp $
#

use strict;
use Carp;
use vars qw(%entity %file %used %file_in_dir
	    $cur_id $on_table $in_question);

my $entity = "include/chapters.ent";
parse($entity);

header();
parse("book.sgml");
footer();

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

	    scan($buf);
	}
	$rh->close();
    }
    else {
	croak("cannot open \"$file\"\n");
    }
}


sub scan
{
    my ($buf) = @_;

    if ($buf =~ /id=\"(\S+)\"/) {
	$cur_id = $1;
	return;
    }

    if ($buf =~ /TABLE_OF_RECIPES/) {
	$on_table = 1;
	return;
    }

    if ($on_table) {
	if ($buf =~ /<question>/) {
	    $in_question = 1;
	    return;
	}
	if ($buf =~ /<\/question>/) {
	    $in_question = 0;
	    return;
	}
    }

    return if $buf =~ /<para>/;
    return if $buf =~ /<\/para>/;

    if ($in_question) {
	print "<para>\n";
	print "<link linkend=\"$cur_id\">\n";
	# print "<xref linkend=\"$cur_id\">\n";
	print $buf;
	print "</link>\n";
	print "</para>\n\n";
    }
}


sub header
{
    print "<sect1 id=\"recipes\">\n";
    print "<title>\n";
    print "list of recipes\n";
    print "</title>\n";
}


sub footer
{
    print "</sect1>\n";
}
