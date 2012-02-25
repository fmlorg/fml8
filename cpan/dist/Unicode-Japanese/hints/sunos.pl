
use strict;

print "**** hints/sunos.pl ****\n";

my $hdr = <<EOF;
#include <fcntl.h>
EOF

Unicode::Japanese::MakeMaker::enableXS('sunos',$hdr,undef);
