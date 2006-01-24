#-*- perl -*-
#
#  Copyright (C) 2003 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: get_value_as_array_ref.pl,v 1.2 2003/07/21 03:43:56 fukachan Exp $
#

use strict;
use Carp;

my $file     = "/tmp/io.$$";
my $map      = "file:$file";
my $key      = 'fukachan@example.com';
my $debug    = defined $ENV{ 'debug' } ? 1 : 0;
my $password = crypt($key, $key);

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("file get_value_as_array_ref");

$tool->set_content($file, "$key $password");

use IO::Adapter;
my $obj = new IO::Adapter $map;
$obj->open();

my $a   = $obj->get_key_values_as_array_ref( $key );
my $pwd = _read($file);

$tool->set_title("file get_value_as_array_ref [0]");
my $p   = $a->[0];
my $pn  = $pwd->{ $key }->[0];
$tool->diff($p, $pn);

$tool->set_title("file get_value_as_array_ref [1]");
my $p   = $a->[1];
my $pn  = $pwd->{ $key }->[1];
$tool->diff($p, $pn);

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
