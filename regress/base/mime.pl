#!/usr/bin/env perl
#
# $FML: mime.pl,v 1.8 2002/04/18 14:18:07 fukachan Exp $
#

use strict;
use Carp;
use MIME::Base64;
use MIME::QuotedPrint;

my $debug = defined $ENV{'debug'} ? 1 : 0;

use Mail::Message::Encode;
my $obj = new Mail::Message::Encode;

&try_mime(" ");
&try_mime("　");
&try_mime("\n");
&try_mime("", 3);

exit 0;


sub try_mime
{
    my ($separator, $xbuf) = @_;
    my $buf = "\n";

    my $orig_str   = "さくら". $separator . $xbuf . "映画版";
    my $in_str_b64 = $obj->encode_mime_string($orig_str);
    my $in_str_qp  = $obj->encode_mime_string($orig_str, 'qp');

    $buf .=  ">". $orig_str. "<\n";
    $buf .=  ">". $in_str_b64. "<\n";
    $buf .=  ">". $in_str_qp. "<\n";

    my $out_str_b64 = $obj->decode_mime_string($in_str_b64, 'euc-jp');
    $buf .=  "<". $out_str_b64. "<\n";

    my $out_str_qp = $obj->decode_mime_string($in_str_qp, 'euc-jp');
    $buf .=  "<". $out_str_qp. "<\n";

    $buf =~ s/\n/\n   |/g;
    print $buf, "\n" if $debug;
    print ($orig_str eq $out_str_b64 ? "base64 ... ok\n" : "fail\n");
    print ($orig_str eq $out_str_qp  ? "qp     ... ok\n" : "fail\n");
}


1;
