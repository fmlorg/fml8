## ----------------------------------------------------------------------------
# t/emoji-jsky-utf8.t
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------

use strict;
#use warnings;
use Test::More tests => 4 * 6 * 2 + 2 * 6 * 2 + 4;

# -----------------------------------------------------------------------------
# load module
#
use Unicode::Japanese;

&test_set_get;

sub xs { _conv('Unicode::Japanese', @_); }
sub pp { _conv('Unicode::Japanese::PurePerl', @_); }
sub _conv
{
  my $pkg   = shift;
  my $str   = shift;
  my $icode = shift || 'utf8-jsky';
  $pkg->new($str, $icode)->utf8;
  #unpack("H*",$pkg->new($str, $icode)->utf8);
}
sub xsj { _conv('Unicode::Japanese', shift, "sjis-jsky"); }
sub ppj { _conv('Unicode::Japanese::PurePerl', shift, "sjis-jsky"); }
sub utf8 { shift }

sub test_set_get
{
  foreach my $spec (
    # G=>U+E001-U+E05a (ee8081-ee819a)
    ["\xee\x80\x80", undef, "e000: out of range"],
    ["\xee\x80\x81", "G!",  "e001: "],
    ["\xee\x81\x9a", "Gz",  "e05a: "],
    ["\xee\x81\x9b", undef, "e05b: out of range"],
    # E=>U+E101-U+E15a (ee8481-ee859a)
    ["\xee\x84\x80", undef, "e100: out of range"],
    ["\xee\x84\x81", "E!",  "e101: "],
    ["\xee\x85\x9a", "Ez",  "e15a: "],
    ["\xee\x85\x9b", undef, "e15b: out of range"],
    # F=>U+E201-U+E25a (ee8881-ee899a)
    ["\xee\x88\x80", undef, "e200: out of range"],
    ["\xee\x88\x81", "F!",  "e201: "],
    ["\xee\x89\x9a", "Fz",  "e25a: "],
    ["\xee\x89\x9b", undef, "e25b: out of range"],
    # O=>U+E301-U+E34D (ee8c81-ee8d8d)
    ["\xee\x8c\x80", undef, "e300: out of range"],
    ["\xee\x8c\x81", "O!",  "e301: "],
    ["\xee\x8d\x8d", "Om",  "e34d: "],
    ["\xee\x8d\x8e", undef, "e34e: out of range"],
    # P=>U+E401-U+E44C (ee9081-ee918c)
    ["\xee\x90\x80", undef, "e400: out of range"],
    ["\xee\x90\x81", "P!",  "e401: "],
    ["\xee\x91\x8c", "Pl",  "e44c: "],
    ["\xee\x91\x8d", undef, "e44d: out of range"],
    # Q=>U+E501-U+E537 (ee9481-ee94b7)
    ["\xee\x94\x80", undef, "e500: out of range"],
    ["\xee\x94\x81", "Q!",  "e501: "],
    ["\xee\x94\xb7", "QW",  "e537: "],
    ["\xee\x94\xb8", undef, "e538: out of range"],
    ["\xee\x94\xb9", undef, "e539: out of range"],
    ["\xee\x94\xba", undef, "e53a: out of range"],
  )
  {
    my ($u8, $out_src, $note) = @$spec;
    my $out = $out_src ? xsj("\e\$$out_src\x0f") : utf8($u8);
    is(xs($u8), $out, "(xs/set) $note");
    is(pp($u8), $out, "(pp/set) $note");
    
    if( $out_src )
    {
      is(Unicode::Japanese->new("\e\$$out_src\x0f","sjis-jsky")->utf8_jsky, $u8, "(xs/get) $note");
      is(Unicode::Japanese::PurePerl->new("\e\$$out_src\x0f","sjis-jsky")->utf8_jsky, $u8, "(xs/get) $note");
    }
  }
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
