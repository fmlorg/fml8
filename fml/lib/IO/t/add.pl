#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: delete.pl,v 1.6 2002/08/19 15:19:46 fukachan Exp $
#

use strict;
use Carp;

my $org_file = "/etc/passwd";
my $file     = "/tmp/passwd";
my $tmpf     = "/tmp/passwd.tmp";
my $map      = "file:". $file;
my $addr     = $ENV{'USER'};

### MAIN ###
print "${map}->add() ";

unlink $file if -f $file;
system "touch $file";

# orignal
my $buf;
my $orgbuf   = GetContent($file);

# append
use IO::Adapter;
my $obj = new IO::Adapter $map;

print "\n";

$obj->add( 'rudo' );
$obj->add( $addr ) || warn("cannot add to $map");
$obj->add( 'kenken' );
if ( $obj->error() ) { print $obj->error();}
show($obj, $addr);

$obj->delete( $addr ); 
$obj->add( $addr , crypt($addr, $$) ) || warn("cannot add to $map");
if ( $obj->error() ) { print $obj->error();}
show($obj, $addr);

my $array = [ 's=skip', 'm=matome', 'r=relayserver', '# comment' ];
$obj->delete( $addr ); 
$obj->add( $addr , $array ) || warn("cannot add to $map");
if ( $obj->error() ) { print $obj->error();}
show($obj, $addr);

exit 0;


if ($buf eq $orgbuf) {
    print " ... ok\n";
}
else {
    print " ... fail <$buf> ne <$orgbuf>\n";
}


$map = 'unix.group:fml';
print "${map}->delete()    ... ";
$obj = new IO::Adapter $map;
eval q{ $obj->delete( $buffer ); };
if ($@) {
    print "ok\n"; # XXX fail (non null $@) is ok here.
}
else {
    print "fail"        unless $@;
    print "<", $obj->error, ">" if $obj->error;
    print "\n";
}

exit 0;


sub GetContent
{
    my ($file) = @_;
    my $buf;

    use FileHandle;
    my $fh = new FileHandle $file;
    while (<$fh>) { $buf .= $_;}
    close($fh);

    $buf;
}


sub show
{
    my ($obj, $addr) = @_;

    $obj->open();
    my $a = $obj->get_value_as_array_ref( $addr );
    $obj->close();

    print "\n=========\n";
    print $addr, "\t=>\t", join(" | ", @$a), "\n";
    print "\n";
    system "cat $file";
}
