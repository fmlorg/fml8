#!/usr/bin/perl
#
use strict;
use Jcode;
BEGIN {
    if ($] < 5.008001){
        print "1..0 # Skip: Perl 5.8.1 or later required\n";
        exit 0;
    }
    require Test::More;
    Test::More->import(tests => 6);
    
}

my ($str,$check,$line);
my $kin = [qw/、 。 ! ?/];

is( jcode('ｱｲｳｴｵｶｷｸｹｺあいうえおabc漢字1234αβ＠★')->jfold(10,'-'),
    jcode('ｱｲｳｴｵｶｷｸｹｺ-あいうえお-abc漢字123-4αβ＠★'), 'jfold() 1' );

is( jcode('ｱｲｳｴｵｶｷｸｹｺあいうえおabc漢字1234αβ＠★')->jfold(9,'-'),
    jcode('ｱｲｳｴｵｶｷｸｹ-ｺあいうえ-おabc漢字-1234αβ-＠★'), 'jfold() 2' );

# Very simple japanese hyphenation;
# Currently, line head japanese hyphenation is only available.
# If you have any complaints and need more, you can expand with
# your class inherited from Jcode.

is( jcode('あいうえおかきくけこさしすせそ。')->jfold(10,'-',$kin),
    jcode('あいうえお-かきくけこ-さしすせそ。'), 'jfold() with kinsoku 1' );

is( jcode('あいうえお、かきくけこさしすせそ。')->jfold(10,'-',$kin),
    jcode('あいうえお、-かきくけこ-さしすせそ。'), 'jfold() with kinsoku 2' );

is( jcode('あいうえお!?')->jfold(10,'-',$kin),
    jcode('あいうえお!?'), 'jfold() with kinsoku 3' );

my @a = ('12345','67890', '0');
my @b = Jcode->new('12345678900')->jfold(5);
is_deeply(\@a, \@b, 'Reported by Iwamoto')
__END__

