#!/usr/local/bin/perl

use strict;
use Carp;
use FML::MIME qw(decode_mime_string encode_mime_string);
use MIME::Base64;


&try_mime("");
&try_mime("　");
&try_mime("\n");

exit 0;


sub try_mime
{
    my ($separator) = @_;

    my $orig_str = "うじゃ". $separator ."あじゃじゃ";
    my $in_str   = encode_mime_string($orig_str);
    my $out_str  = decode_mime_string($in_str, {charset => 'euc-japan'}), 

    print "   >", $orig_str, "<\n";
    print "   >", $in_str, "<\n";
    print "   <", $out_str, "<\n";
    print ($orig_str eq $out_str ? "ok\n" : "fail\n");
}

1;
