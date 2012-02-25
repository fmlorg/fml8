#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/v041_sjisau.t
# -----------------------------------------------------------------------------
# Mastering programmed by SANO Taku (SAWATARI Mikage)
#
# Copyright 2007 SANO Taku (SAWATARI Mikage)
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use strict;
use Test::More tests => 1+2;

use Unicode::Japanese;

&check();
&test_sjis_au();

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
# test_sjis_au.
#
sub test_sjis_au
{
	my $xs = Unicode::Japanese->new();
	my $pp = Unicode::Japanese::PurePerl->new();
	
	is($xs->set($xs->set("沼・")->sjis_au, "sjis-au")->get, "沼・", "[sjis_au] check (xs)");
	is($pp->set($pp->set("沼・")->sjis_au, "sjis-au")->get, "沼・", "[sjis_au] check (pp)");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
