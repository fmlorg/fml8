#
# $Id: length.t,v 0.1 2002/05/03 00:20:47 dankogai Exp $
#
# This script is in EUC-JP

use strict;

use Jcode;
use Test;

eval qq{ use bytes; }; # for sure

my %Tests = 
    (
     'あいうえお' => 5,
     'あxxx'      => 4,
     'あ あ '     => 4,
     'aaa'        => 3,
     "ホゲ\nホゲ\n" => 6,
    );

plan tests => (scalar keys %Tests);

while (my($str, $len) = each %Tests) {
    ok( Jcode->new($str)->jlength, $len );
}



