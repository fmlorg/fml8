#-*- perl -*-
#
#  Copyright (C) 2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML$
#

use strict;
use Carp;
use vars qw(@stack);

my $debug    = 0;
my $file     = "/tmp/pcre";
my $map      = "pcre:$file";
my $addr     = $ENV{'USER'};

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("pcre find");

unlink $file if -f $file;
system "touch $file";

use FileHandle;
my $wh = new FileHandle "> $file";
if (defined $wh) {
    push(@stack, '\S+\@example\.com');
    print $wh '\S+\@example\.com', "\n";
    $wh->close();
}

use IO::Adapter;
my $obj = new IO::Adapter $map;

_find( $obj, 'fukachan@example.com',   1);
_find( $obj, '\S+@example.com',        1);
_find( $obj, 'fukachan@example.co.jp', 0);
_find( $obj, '\S+@example.co.jp',      0);
_find( $obj, '\S+@\S+',                0);

exit 0;


sub _find
{
    my ($obj, $s, $expect_success) = @_;
    my $msg = "pcre find ($s)";

    my $r = $obj->find($s);
    if ($expect_success) {
	if ($r eq $s) {
	    $tool->print_ok($s);
	}
	else {
	    $tool->print_error($s);	    
	}
    }
    else {
	if ($r eq '') {
	    $tool->print_ok($s);
	}
	else {
	    $tool->print_error($s);	    
	}
    }
}
