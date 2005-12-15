#!/usr/bin/env perl
#-*- perl -*-
#
# $FML: listup_recipes.pl,v 1.1 2005/11/19 03:50:51 fukachan Exp $
#

#
# *** CAUTION: THIS FILE CODE IS JAPANESE EUC. ***
#

use strict;
use Carp;
use vars qw(%entity %file %used %file_in_dir
	    $cur_id $on_table $in_question $in_sect2 $in_itemizedlist
	    $found_chapter $found_title);

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
	if ($buf =~ /<chapter\s+/i) { 
	    $found_chapter = 1;
	}
	$cur_id = $1;
	return;
    }

    if ($buf =~ /<title>/i) { 
	$found_title = 1;
	return;
    }

    if ($buf =~ /TABLE_OF_RECIPES/) {
	$on_table = 1;
	return;
    }

    if ($found_chapter && $found_title) {
	if ($in_sect2) {
	    if ($in_itemizedlist) {
		print "</itemizedlist>\n";
		$in_itemizedlist = 0;
	    }
	    print "</sect2>\n\n";
	}

	print "<sect2>\n";
	print "<title>\n";
	print "$buf\n";
	print "</title>\n";
	print "<para></para>\n";
	print "\n";
	$found_chapter = $found_title = 0;
	$in_sect2 = 1;
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
	unless ($in_itemizedlist) {
	    print "<itemizedlist>\n";
	    $in_itemizedlist = 1;
	}

	print "<listitem>\n";
	print "<para>\n";
	print "<link linkend=\"$cur_id\">\n";
	# print "<xref linkend=\"$cur_id\">\n";
	print $buf;
	print "</link>\n";
	print "</para>\n\n";
	print "</listitem>\n";
    }
}


sub header
{
    print "<sect1 id=\"recipes\">\n";
    print "<title>\n";
    if ($ENV{ LANG_HINT } eq 'ja') {
	print "レシピ一覧";
    }
    else {
	print "List of Recipes\n";
    }
    print "</title>\n";
}


sub footer
{
    if ($in_sect2) {
	print "</sect2>\n\n";
    }

    print "</sect1>\n";
}
