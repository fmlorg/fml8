use lib qw(./lib/fml5 ./lib/CPAN ./lib/3RDPARTY ./lib);
use FML::String qw(STR2EUC);

for (@ARGV) {
    my $x = &STR2EUC($_);
    print "<$_> -> <$x>\n";
}
