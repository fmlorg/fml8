#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: search_max_id.pl,v 1.1 2001/11/20 07:02:57 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);

use Benchmark;

use File::Sequence;
my $obj = new File::Sequence;
my $max_id = $ENV{'max_id'};

for my $file (@ARGV) {
    my %db = ();
    my $f  = $file; $f =~ s/\.\w+$//;

    use AnyDBM_File;
    use Fcntl;
    tie %db, 'AnyDBM_File', $f, O_RDWR|O_CREAT, 0644;

    print STDERR "\nsearch with pebot:\n";
    print STDERR "max = ";
    my $t0 = new Benchmark;
    print STDERR $obj->search_max_id( { hash => \%db } );
    my $t1 = new Benchmark;
    my $td = timediff($t1, $t0);
    print STDERR " ", timestr($td), "\n";


    print STDERR "\nfull search:\n";
    print STDERR "max = ";
    my $t0 = new Benchmark;
    print STDERR $obj->search_max_id( { 
	hash => \%db,
	full_search => 1,
    } );
    my $t1 = new Benchmark;
    my $td = timediff($t1, $t0);
    print STDERR " ", timestr($td), "\n";

}

exit 0;
