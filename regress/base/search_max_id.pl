#!/usr/bin/env perl
#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: @template.pm,v 1.2 2001/10/27 04:27:18 fukachan Exp $
#

use strict;
use lib qw(../../fml/lib ../../cpan/lib ../../img/lib);

use File::Sequence;
my $obj = new File::Sequence;

for my $file (@ARGV) {
    my %db = ();
    my $f  = $file; $f =~ s/\.\w+$//;

    use AnyDBM_File;
    use Fcntl;
    tie %db, 'AnyDBM_File', $f, O_RDWR|O_CREAT, 0644;

    print STDERR "max = ";
    print STDERR $obj->search_max_id( { hash => \%db } );
    print STDERR "\n";
}

exit 0;
