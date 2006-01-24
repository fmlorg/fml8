#-*- perl -*-
#
#  Copyright (C) 2001,2003,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: add.pl,v 1.2 2003/07/21 03:43:56 fukachan Exp $
#

use strict;
use Carp;
use vars qw(@stack);

my $debug    = 0;
my $file     = "/tmp/passwd";
my $map      = "file:$file";
my $addr     = $ENV{'USER'};

### MAIN ###
use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title( "file rewrite (add|delete)" );

unlink $file if -f $file;
system "touch $file";

# option
my $array = [ 's=skip', 'm=matome', 'r=relayserver', '# comment' ];

use IO::Adapter;
my $obj = new IO::Adapter $map;

_add( $obj,  'rudo' );
_add( $obj,  $addr );
_add( $obj,  'kenken' ); 

_delete( $obj, $addr ); 

_add( $obj,  $addr , [ crypt($addr, $$) ] );
_delete( $obj, $addr );

_add( $obj,  $addr , $array );

exit 0;


sub _add
{
    my ($obj, $addr, $array) = @_; 

    $obj->add( $addr, $array );
    if ( $obj->error() ) { $tool->error( $obj->error() );}

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
    if ( $obj->error() ) { $tool->error( $obj->error() );}

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

    print "? ($#$a != $#$b)\n" if $debug;
    if ($#$a != $#$b) {
	croak("number of array differs (@$a != @$b)\n");
    }

    for (my $i = 0; $i <= $#$a; $i++) {
	print "? ($a->[ $i ] ne $b->[ $i ])\n" if $debug;
	if ($a->[ $i ] ne $b->[ $i ]) {
	    croak("differ ($a->[ $i ] ne $b->[ $i ])\n");
	}
    }

    print "\n" if $debug;
}
