

use strict;

print "**** hints/freebsd.pl ****\n";

my $hdr = <<EOF;
#include <fcntl.h>
EOF

Unicode::Japanese::MakeMaker::enableXS('freebsd',$hdr,undef);
