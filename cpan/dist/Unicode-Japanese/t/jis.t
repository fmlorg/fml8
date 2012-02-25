## ----------------------------------------------------------------------------
# t/jis.t
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
use Test;
BEGIN { plan tests => 20, };

# -----------------------------------------------------------------------------
# load module

use Unicode::Japanese;
use lib 't';
require 'esc.pl';
my $xs = Unicode::Japanese->new();
my $pp = Unicode::Japanese::PurePerl->new();
sub jisToUtf8_xs($){ tt($xs->set($_[0],'jis')->utf8()); }
sub jisToUtf8_pp($){ tt($pp->set($_[0],'jis')->utf8()); }
sub jisToSjis_xs($){ tt($xs->set($_[0],'jis')->sjis()); }
sub jisToSjis_pp($){ tt($pp->set($_[0],'jis')->sjis()); }
sub jisToJis_xs($){ tt($xs->set($_[0],'jis')->jis()); }
sub jisToJis_pp($){ tt($pp->set($_[0],'jis')->jis()); }
sub tt($){ escfull($_[0]) }
sub bin($){ escfull(pack("H*",join('',split(' ',$_[0])))); }

{
  # ASCII : \e(B 
  #
  my $test = "\e(B123ABC\e(B123";
  my $correct = tt("123ABC123");
  ok(jisToUtf8_xs($test),$correct,"escape to ASCII (xs)");
  ok(jisToUtf8_pp($test),$correct,"escape to ASCII (pp)");
}

{
  # jis.roman : \e(J
  #
  my $test = "\e(J123ABC\e(B123";
  my $correct = tt("123ABC123");
  ok(jisToUtf8_xs($test),$correct,"escape to jis.roman (xs)");
  ok(jisToUtf8_pp($test),$correct,"escape to jis.roman (pp)");
}

{
  # jis.kana : \e(I
  #
  my $test = "\e(I123ABC\e(B123";
  my $correct_utf8 = bin("ef bd b1 ef bd b2 ef bd b3 ef be 81 ef be 82 ef be 83 31 32 33");
  my $correct_sjis = bin("b1 b2 b3 c1 c2 c3 31 32 33");
  ok(jisToSjis_xs($test),$correct_sjis,"escape to jis.kana (xs/sjis)");
  ok(jisToSjis_pp($test),$correct_sjis,"escape to jis.kana (pp/sjis)");
  ok(jisToUtf8_xs($test),$correct_utf8,"escape to jis.kana (xs/utf8)");
  ok(jisToUtf8_pp($test),$correct_utf8,"escape to jis.kana (pp/utf8)");
}
{
  # jis.kana(so/si)
  #
  my $test = "\x0e123ABC\x0f123";
  my $correct = bin("ef bd b1 ef bd b2 ef bd b3 ef be 81 ef be 82 ef be 83 31 32 33");
  #skip("so/si not supported yet",jisToUtf8_xs($test),$correct,"escape to jis.roman (xs)");
  #skip("so/si not supported yet",jisToUtf8_pp($test),$correct,"escape to jis.roman (pp)");
}

{
  # jis-c-6226-1979(old-JIS) : \e$@
  # jis-x-0208-1983(new-JIS) : \e$B
  # jis-x-0208-1990 : \e&@\e$B
  my $test_old_jis = "\e\$\@!!\e(B";
  my $test_new_jis = "\e\$B!!\e(B";
  my $test_jis1990 = "\e&\@\e\$B!!\e(B";
  my $correct = tt("\x81\x40");
  ok(jisToSjis_xs($test_old_jis),$correct,"old-jis to sjis (xs)");
  ok(jisToSjis_pp($test_old_jis),$correct,"old-jis to sjis (pp)");
  ok(jisToSjis_xs($test_new_jis),$correct,"new-jis to sjis (xs)");
  ok(jisToSjis_pp($test_new_jis),$correct,"new-jis to sjis (pp)");
  ok(jisToSjis_xs($test_jis1990),$correct,"jis1990 to sjis (xs)");
  ok(jisToSjis_pp($test_jis1990),$correct,"jis1990 to sjis (pp)");
}

{
  # jis-x-0212-1990: \e$(D
  #skip("jis-x-0212 not ready");
  #skip("jis-x-0212 not ready");
  my $test = "\e\$(D!!\e(B";
  my $correct = tt("\x81\xac");
  ok(jisToSjis_xs($test),$correct,"jis0212 to sjis (xs)");
  ok(jisToSjis_pp($test),$correct,"jis0212 to sjis (pp)");
}

{
  # resume to ascii on newline. : \e(B 
  #  JIS X 0208-1983  \e$B
  my $test1 = "\e\$B!!\n!!!";
  my $correct1_sjis = tt("\x81\x40\n!!!");
  my $correct1_jis = tt("\e\$B!!\e(B\n!!!");
  ok(jisToSjis_xs($test1),$correct1_sjis,"resume to ASCII (xs)");
  ok(jisToSjis_pp($test1),$correct1_sjis,"resume to ASCII (pp)");
  ok(jisToJis_xs($test1), $correct1_jis, "resume to ASCII (xs)");
  ok(jisToJis_pp($test1), $correct1_jis, "resume to ASCII (pp)");
}


# -----------------------------------------------------------------------------
# End Of File.
# -----------------------------------------------------------------------------
