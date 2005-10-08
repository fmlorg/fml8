#!/usr/bin/env perl
#
# $FML$
#

use Mail::Message::Charset;

use Mail::Message::Charset;
my $mc = new Mail::Message::Charset;



$subject = '=?ISO-2022-JP?B?GyRCOkc9Kko8NG8hRBsoQg==?=';

if ($subject =~ /=\?iso-2022-jp\?/i) {
    $in_code  = 'jis-jp';
    $out_code = 'euc-jp';
}

print "  in $in_code\n";
print " out $out_code\n";

if ($subject =~ /=\?([-\w\d]+)\?/i) {
    my $lang = $mc->message_charset_to_language($1);
    print "lang $lang\n";

    $in_code  = $mc->language_to_message_charset($lang);
    $out_code = $mc->language_to_internal_charset($lang);
}

print "  in $in_code\n";
print " out $out_code\n";

exit 0;
