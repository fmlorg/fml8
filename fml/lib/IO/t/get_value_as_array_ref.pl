#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get_value_as_array_ref.pl,v 1.1 2003/02/11 14:20:32 fukachan Exp $
#

use strict;
use Carp;

my $org_file = "/var/spool/ml/elena/etc/passwd-admin";
my $map      = "file:". $org_file;
my $addr     = $ENV{'USER'};
my $key      = 'fukachan@sapporo.iij.ad.jp';
my $debug    = defined $ENV{ 'debug' } ? 1 : 0;

### MAIN ###
print "${map}->get_value_as_array_ref() ... ";

print "ignored\n";
exit 0;

# append
use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open();

#
# 1. compare passwords.
#
my $a   = $obj->get_value_as_array_ref( $key );
my $p   = $a->[0];
my $pwd = _read($org_file);
my $pn  = $pwd->{ $key }->[ 1 ];

if ($p eq $pn) {
    print "ok\n";
}
else {
    print "not ok ('$p' ?= '$pn')\n";
}

if ($debug) {
    my $i = 0;
    for my $p (@$a) {
	print STDERR ++$i, "\t=>\t", $p, "\n";
    }
}

exit 0;


sub _read
{
    my ($file) = @_;
    my $h = {};

    use FileHandle;
    my $fh = new FileHandle $file;

    if (defined $fh) {
	my $buf;
	while ($buf = <$fh>) {
	    my ($k, @v) = split(/\s+/, $buf);

	    $h->{ $k } = [ $k, @v ];
	}
	$fh->close();
    }

    return $h;
}
