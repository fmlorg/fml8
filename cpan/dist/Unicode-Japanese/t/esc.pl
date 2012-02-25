## ----------------------------------------------------------------------------
# esc.pl
# -----------------------------------------------------------------------------
# require 'esc.pl'
#  (used from t/*.t)
#  (ja:) (t/*.t でつかってたり)
# -----------------------------------------------------------------------------
# escapes coltroll characters.
# esc() effects only 0x00-0x7F.
# escfull() effect all chats includes utf-8 char which will be in \x{hh} format.
# (ja:) 制御文字とかをエスケープする.
# (ja:) 0x80以降は残す時は esc で,
# (ja:) 全部エスケープする時は escfull .
# -----------------------------------------------------------------------------

sub esc
{
  my $str = shift;
  $str =~ s/\\/\\\\/g;
  $str =~ s/\n/\\n/g;
  $str =~ s/\e/\\e/g;
  $str =~ s/\r/\\r/g;
  $str =~ s/\0/\\0/g;
  $str =~ s/([\x00-\x1f\x7f])/sprintf('\x%02x',ord($1))/ge;
  $str;
}

sub escfull
{
  my $str = shift;
  $str =~ s/\\/\\\\/g;
  $str =~ s/\n/\\n/g;
  $str =~ s/\e/\\e/g;
  $str =~ s/\r/\\r/g;
  $str =~ s/\0/\\0/g;
  $str =~ s/([\x00-\x1f\x7f-\xff])/sprintf('\x%02x',ord($1))/ge;
  $str =~ s/([^\x00-\xff])/sprintf('\x{%02x}',ord($1))/ge;
  $str;
}

1;
