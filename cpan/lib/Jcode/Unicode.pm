#
# $Id: Unicode.pm,v 1.2 2001/05/18 05:14:38 dankogai Exp $
#

package Jcode::Unicode;

use strict;
use vars qw($RCSID $VERSION @ISA @EXPORT $PEDANTIC);

$RCSID = q$Id: Unicode.pm,v 1.2 2001/05/18 05:14:38 dankogai Exp $;
$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Carp;
require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

$PEDANTIC ||= 0;

bootstrap Jcode::Unicode $VERSION;

# Merge these subs to Jcode

sub Jcode::ucs2_euc{
    my ($thingy, $pedantic) = @_; $pedantic ||= 0;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    return
        $$r_str = Jcode::Unicode::ucs2_euc($$r_str, $pedantic);
}

sub Jcode::euc_ucs2{
    my ($thingy, $pedantic) = @_; $pedantic ||= 0;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    return
        $$r_str = Jcode::Unicode::euc_ucs2($$r_str, $pedantic);
}

sub Jcode::ucs2_utf8{
    my ($thingy, $pedantic) = @_;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    return
        $$r_str = Jcode::Unicode::ucs2_utf8($$r_str);
}

sub Jcode::utf8_ucs2{
    my ($thingy) = @_;
        my $r_str = ref $thingy ? $thingy : \$thingy;
    return
        $$r_str = Jcode::Unicode::utf8_ucs2($$r_str);
}


sub Jcode::euc_utf8{
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    &Jcode::euc_ucs2($r_str);
    &Jcode::ucs2_utf8($r_str);
}

sub Jcode::utf8_euc{
    my $thingy = shift;
    my $r_str = ref $thingy ? $thingy : \$thingy;
    &Jcode::utf8_ucs2($r_str);
    &Jcode::ucs2_euc($r_str);
}

1;
__END__

=head1 NAME

Jcode::Unicode - Aux. routines for Jcode

=head1 SYNOPSIS

NONE

=head1 DESCRIPTION

This module implements following subs as XS.  Used via Jcode.pm.

This module is called by Jcode.pm on demand.  This module is not intended for
direct use by users.  This modules implements functions related to Unicode.  
Following functions are defined here;

=over 4

=item Jcode::ucs2_euc();

=item Jcode::euc_ucs2();

=item Jcode::ucs2_utf8();

=item Jcode::utf8_ucs2();

=item Jcode::euc_utf8();

=item Jcode::utf8_euc();

=back

=cut

=head1 VARIABLES

=over 4

=item B<$Jcode::Unicode::PEDANTIC>

When set to non-zero, x-to-unicode conversion becomes pedantic.  
That is, '\' (chr(0x5c)) is converted to zenkaku backslash and 
'~" (chr(0x7e)) to JIS-x0212 tilde.

By Default, Jcode::Unicode leaves ascii ([0x00-0x7f]) as it is.

=back

=cut

=head1 BUGS

If any, that is Unicode, Inc. to Blame (Especially JIS0201.TXT).

=head1 SEE ALSO

http://www.unicode.org/

=head1 COPYRIGHT

Copyright 1999 Dan Kogai <dankogai@dan.co.jp>

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Unicode conversion table used here are based uponon files at
ftp://ftp.unicode.org/Public/MAPPINGS/EASTASIA/JIS/,
Copyright (c) 1991-1994 Unicode, Inc.

=cut
