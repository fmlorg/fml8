use lib qw(./lib/fml5 ./lib/CPAN ./lib/3RDPARTY ./lib);
# use strict;
use Carp;

use Mail::Header;
use FML::Parse;

my ($head, $body) = new FML::Parse \*STDIN;

my $s = {
    header => $head,
    body   => $body,
};


$s->{'header'}->delete('Received');
$s->{'header'}->print;
print "\n\n";
print ${ $s->{'body'} };

use FML::Debug;
my $fp = new FML::Debug;
$fp->show_structure( \$s );

for (1.. 100) {
    ${ "x$_" } = $s;
system "ps auxww|grep $$";
}

exit 0;
