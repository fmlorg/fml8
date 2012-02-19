
use ExtUtils::testlib;
use Jcode::Unicode;
use Getopt::Std;
getopts("p");

my $file = "../t/table.euc";
my $euc, $ucs2, $utf8;
open F,  $file or die $!;
read F, $euc, -s $file;

print "1..2\n";
print "Ok 1\n" if $ucs2  = Jcode::Unicode::euc_ucs2($euc, $opt_p);
print "Ok 2\n" if $euc  eq Jcode::Unicode::ucs2_euc($ucs2, $opt_p);
print "Ok 3\n" if $utf8  = Jcode::Unicode::ucs2_utf8($ucs2);
print "Ok 4\n" if $ucs2 eq Jcode::Unicode::utf8_ucs2($utf8);
