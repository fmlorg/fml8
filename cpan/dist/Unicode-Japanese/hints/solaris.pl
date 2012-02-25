
use strict;

print "**** hints/solaris.pl ****\n";

Unicode::Japanese::MakeMaker::remove_ccflags('-Wall');
Unicode::Japanese::MakeMaker::enableXS('solaris',undef,undef);
