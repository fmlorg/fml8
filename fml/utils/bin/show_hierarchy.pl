#!/usr/bin/env perl
#
# $FML: show_hierarchy.pl,v 1.3 2002/04/01 23:41:24 fukachan Exp $
#

use lib qw(./lib/3RDPARTY ./lib/fml5 ./lib/CPAN ./lib);
use strict;
use vars qw($Count %Count $debug $verbose %IgnoreList);

%IgnoreList = (
	       'Carp'        => 1,
	       'Exporter'    => 1,
	       'FileHandle'  => 1,
	       'DynaLoader'  => 1,
	       'AutoLoader'  => 1,
	       );

for (@ARGV) { load( $_ );}


sub load
{
    my ($f) = @_;
    my $name = $f;

    return if $IgnoreList{ $name };

    $Count++;
    if ($Count > 32) { die("infinite loop!\n");}

    $f =~ s@::@/@g;
    for my $dir (@INC) {
	if (-f "$dir/$f.pm") {
	    $f = "$dir/$f.pm";
	    last;
	}
	if (-f "$dir/$f.pl") {
	    $f = "$dir/$f.pl";
	    last;
	}
    }

    unless (-f $f) {
	P( "not found: $f" ) if $debug;;
	$Count--;
	return;
    }


    if ( $Count{ $f } ) {
	P( "$f is recursive" ) if $debug;;
	$Count--;
	return;
    }
    else {
	$Count{ $f } = 1;
    }

    use FileHandle;
    my $fh = new FileHandle $f;
    print "--- open $f\n" if $debug;


    ### dynamic scope to count up recursive conditions
    local(%Count) if $Count == 2;



    if (defined $fh) {
	my $file = '';
	my $comment = '';
	my $current_function = '';
	my %function_hach = ();
	my $pat = '$0 eq __FILE__';

	while (<$fh>) {
	    last if /$pat/;
	    last if /__END__/;

	    next if /^\s*\#/;
	    next if /^\s*Log/;

	    # ignore comments
	    $comment = 1 if /^=/;
	    $comment = 0 if /^=cut/;
	    next if $comment;

	    chop;

	    if (/^sub (\S+)/) {
		$current_function = $1;
	    }

	    # ignore these since they are too many.
	    if (/(use|require)\s+(Carp|Exporter|DynaLoader|AutoLoader)/) {
		next;
	    }

	    if (/(use|require)\s+([A-Z]\S+[a-zA-Z0-9])/) {
		unless ( $function_hach{ $current_function } ) {
		    if ($verbose) {
			&Print();
			&Print( "${name}::". $current_function );
		    }
		    $function_hach{ $current_function } = 1;
		}

		&Print() if $Count == 1;
		&Print() if $Count == 2;
		$verbose ? &Print( $_ , $. ) : &Print( $_ );
		$file = $2;
		$file =~ s/\"//g;
		$file =~ s/\'//g;
		if ($file =~ /^[a-z]/) {
		    ;
		}
		else {
		    P( "\t($Count)load $file" ) if $debug;
		    load($file);
		}
	    }
	}

	$fh->close if defined $fh;
    }

    $Count--;
}


sub Print
{
    my ($s, $lc) = @_;

    $s =~ s/^\s+//o;
    print "   " x ( $Count - 1 );
    printf "%4d> ", $lc if $lc;
    print $s, "\n";
}


1;
