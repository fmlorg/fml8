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
$tool->set_title("pcre rewrite (add|delete)");

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

_add( $obj,  'rudo' );
_add( $obj,  $addr );
_add( $obj,  'kenken' ); 

_delete( $obj, $addr ); 

_add( $obj,  $addr , [ crypt($addr, $$) ] );
_delete( $obj, $addr );

exit 0;


sub _add
{
    my ($obj, $addr, $array) = @_; 

    $obj->add( $addr, $array );
    if ( $obj->error() ) { print $obj->error();}

    if (defined $array && @$array) {
	push(@stack, "$addr @$array");
    }
    else {
	push(@stack, $addr);
    }

    diff($obj);
}


sub _delete
{
    my ($obj, $addr, $array) = @_; 

    $obj->delete( $addr, $array );
    if ( $obj->error() ) { print $obj->error();}

    my (@r) = ();
  STACK:
    for my $s (@stack) {
	my ($x) = split(/\s+/, $s);
	if ($x eq $addr) { next STACK;}
	push(@r, $s);
    }
    @stack = @r;

    diff($obj);
}


sub diff
{
    my ($obj) = @_;
    my (@content) = ();

    $obj->close();
    $obj->open();
    while (my $buf = $obj->get_key_values_as_array_ref()) {
	push(@content, "@$buf");
    }
    $obj->close();

    compare(\@stack, \@content);
}


sub compare
{
    my ($a, $b) = @_;
    my $e = '';

    print "? ($#$a != $#$b)\n" if $debug;
    if ($#$a != $#$b) {
	$e = "number of array differs (@$a != @$b)";
    }

    for (my $i = 0; $i <= $#$a; $i++) {
	print "? ($a->[ $i ] ne $b->[ $i ])\n" if $debug;
	if ($a->[ $i ] ne $b->[ $i ]) {
	    $e = "differ ($a->[ $i ] ne $b->[ $i ])";
	}
    }

    print "\n" if $debug;

    if ($e) {
	$tool->print_error($e);
    }
    else {
	$tool->print_ok();
    }
}
