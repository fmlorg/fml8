#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/v038_guess_imode2.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use strict;
use Test::More tests => 1+76*2;

use Unicode::Japanese;

&check();
&test_guess_imode2();

# -----------------------------------------------------------------------------
# check.
#
sub check
{
	#diag("Unicode::Japanese [$Unicode::Japanese::VERSION]");
	Unicode::Japanese->new();
	my $xs_loaderror = $Unicode::Japanese::xs_loaderror;
	defined($xs_loaderror) or $xs_loaderror = '{undef}';
	is($xs_loaderror, '', "load success");
}

# -----------------------------------------------------------------------------
# test_guess_imode2.
#
sub test_guess_imode2
{
	my $xs = Unicode::Japanese->new();
	my $pp = Unicode::Japanese::PurePerl->new();
	 
	foreach my $i (1..76)
	{
		my $data = "\x82\xb3 \xf9".pack("C",0xb0+$i);
		is($xs->getcode($data), 'sjis-imode', "[guess_imode2] imode-pictgram extend $i (xs)");
		is($pp->getcode($data), 'sjis-imode', "[guess_imode2] imode-pictgram extend $i (pp)");
	}
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
