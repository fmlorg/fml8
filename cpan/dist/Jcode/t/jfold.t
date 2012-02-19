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
my $kin = [qw/�� �� ! ?/];

is( jcode('������������������������������abc����1234���¡���')->jfold(10,'-'),
    jcode('��������������������-����������-abc����123-4���¡���'), 'jfold() 1' );

is( jcode('������������������������������abc����1234���¡���')->jfold(9,'-'),
    jcode('������������������-����������-��abc����-1234����-����'), 'jfold() 2' );

# Very simple japanese hyphenation;
# Currently, line head japanese hyphenation is only available.
# If you have any complaints and need more, you can expand with
# your class inherited from Jcode.

is( jcode('��������������������������������')->jfold(10,'-',$kin),
    jcode('����������-����������-������������'), 'jfold() with kinsoku 1' );

is( jcode('����������������������������������')->jfold(10,'-',$kin),
    jcode('������������-����������-������������'), 'jfold() with kinsoku 2' );

is( jcode('����������!?')->jfold(10,'-',$kin),
    jcode('����������!?'), 'jfold() with kinsoku 3' );

my @a = ('12345','67890', '0');
my @b = Jcode->new('12345678900')->jfold(5);
is_deeply(\@a, \@b, 'Reported by Iwamoto')
__END__

