#!/usr/local/bin/perl
#
# $FML: data2sgml.pl,v 1.1 2001/04/28 14:37:05 fukachan Exp $
#

use strict;
use Carp;
use vars qw(%list @ENTRY);

@ENTRY = ('system',
	  'release',
	  'perl.version',
	  'perl.path',
	  'comments'
	  );

my ($system, $release, $key, $value);
my $in_row = 0;


while (<>) {
    if (/^\s*$/) {
	if ( $list{ 'title' } ) {
	    table_head(\%list, $list{'title'} );
	}
	elsif (%list) {
	    show_row();
	    show_list(\%list);
	}
	undef %list;
    }

    if (/^\[(\S+)\]\s+(.*)/) {
	($key, $value) = ($1, $2);
	$list{ $key } .= $value;
    }
}

print "\t</row>\n";
print "   </tbody>\n";
print " </tgroup>\n";
print "</table>\n";

exit 0;


sub table_head
{
    my ($list, $title) = @_;
    my $cols = length(@ENTRY);

    print "<table>\n";
    print " <title> $title </title>\n\n";
    print " <tgroup cols=$cols>\n";
    print "   <thead>\n";
    print "\t<row>\n";

    show_list( $list );

    print "\t</row>\n";
    print "   </thead>\n\n";
    print "   <tbody>\n";
}


sub show_row
{
    print "\t</row>\n" if $in_row;
    print "\n\t<row>\n";
    $in_row = 1;
}


sub show_list
{
    my ($list) = @_;

    for (@ENTRY) {
	print "\t<entry>", $list->{ $_ }, "</entry>\n";
    }
}
