#!/usr/bin/env perl
#
#  Copyright (C) 2002,2006 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: mime.pl,v 1.9 2002/08/17 05:26:48 fukachan Exp $
#

use strict;
use Carp;
use MIME::Base64;
use MIME::QuotedPrint;

my $debug = defined $ENV{'debug'} ? 1 : 0;

use FML::Test::Utils;
my $tool = new FML::Test::Utils;
$tool->set_title("mime");

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

    $tool->set_title("mime base64");
    $tool->diff($orig_str, $out_str_b64);

    $tool->set_title("mime qp");
    $tool->diff($orig_str, $out_str_qp);
}


1;
