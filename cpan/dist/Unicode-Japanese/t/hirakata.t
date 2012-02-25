
## convert hiragana <-> katakana
#
# hiragana : (A) U+3042, (I) U+3044, (U) U+3046
#                e3.81.82    e3.81.84    e3.81.86
#
# katakana : (A) U+30a2, (I) U+30a4, (U) U+30a6
#                e3.82.a2    e3.82.a4    e3.82.a6
#

use strict;
use Test;
use Carp;
#no I18N::Japanese;
use Unicode::Japanese qw(no_I18N_Japanese);
use lib 't';
require 'esc.pl';
Unicode::Japanese->new();
print "[$Unicode::Japanese::xs_loaderror]\n";
BEGIN { plan tests => 2*2 }

my $string;

$]>=5.008 and eval('use bytes'), $@ && die $@;

my $kata_AIU = "\xe3\x82\xa2\xe3\x82\xa4\xe3\x82\xa6";
my $hira_AIU = "\xe3\x81\x82\xe3\x81\x84\xe3\x81\x86";


# hiragana(A I U) -> katakana(A I U)
# (xs)
$string = Unicode::Japanese->new($hira_AIU);
$string->hira2kata();
ok(escfull($string->utf8()), escfull($kata_AIU));
# (pp)
$string = Unicode::Japanese::PurePerl->new($hira_AIU);
$string->hira2kata();
ok(escfull($string->utf8()), escfull($kata_AIU));

# katakana(A I U) -> hiragana(A I U)
# (xs)
$string = Unicode::Japanese->new($kata_AIU);
$string->kata2hira();
ok(escfull($string->utf8()), escfull($hira_AIU));
# (pp)
$string = Unicode::Japanese::PurePerl->new($kata_AIU);
$string->kata2hira();
ok(escfull($string->utf8()), escfull($hira_AIU));
