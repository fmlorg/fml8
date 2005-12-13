#!/usr/bin/env perl
#-*- perl -*-
#
# $FML$
#

use strict;
use Carp;
use vars qw($total $current_chapter_title $is_title_print);

if (@ARGV) {
    for my $file (@ARGV) {
	read_file($file);
    }
}
else {
    read_file("/dev/stdin");
}

exit 0;

sub read_file
{
    my ($file) = @_;

    use FileHandle;
    my $rh = new FileHandle $file;
    if (defined $rh) {
	my $in_q  = 0;
	my $in_t  = 0;
	my $first = 0;
	my $num_r = 0; 
	my $buf;

	while ($buf = <$rh>) {
	    next if $buf =~ /<para>/;
	    next if $buf =~ /<\/para>/;

	    # chapter title reset
	    if ($buf =~ /<chapter.*>/) { 
		$current_chapter_title = '';
		$is_title_print = 0;
		next;
	    }
	    unless ($current_chapter_title) {
		if ($buf =~ /<title>/i)   { $in_t = 1; next; }
		if ($buf =~ /<\/title>/i) { $in_t = 0; next; }
		if ($in_t) { 
		    $buf =~ s/^\s*//;
		    $buf =~ s/\s*$//;
		    $current_chapter_title .= $buf; 
		    next;
		}
	    }

	    if ($buf =~ /<question>/)   { 
		$in_q = 1;
		$num_r++;
		$total++;

		unless ($is_title_print) {
		    print_chapter_title();
		    $is_title_print = 1;
		}

		unless ($first) { 
		    print "\n-- $file\n" unless $file =~ /\/dev\//;
		    $first = 1;
		}
		print "\n($num_r)\n";
		next;
	    }
	    if ($buf =~ /<\/question>/) { 
		$in_q = 0;
		next;
	    }

	    if ($in_q) { 
		print $buf;
	    }	    
	}
	$rh->close();
    }
}


sub print_chapter_title
{
    print "\n*** ", $current_chapter_title, " ***\n";
}
