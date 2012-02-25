
use strict;
#use warnings;
use Unicode::Japanese;
use Test::More tests => (176 + 76) * 4;

&test;

sub test
{
  my $xs = Unicode::Japanese->new();
  my @data = <DATA>;
  my $conv;
  foreach $conv ('imode1', 'imode2')
  {
    #diag "test $conv\n";
    foreach(@data)
    {
      chomp;
      #/^\w+$/ and print("$_\n");
      /^\w+$/ and next;
      $_ or exit;
      my ($sjis_hex, $ucs2_hex) = split(' ', $_);

      # set utf8-imode.
      my $ucs2_imode   = pack("H*", $ucs2_hex);
      my $u8_imode     = $xs->set($ucs2_imode, "ucs2")->utf8;
      my $u8_from_utf8 = $xs->set($u8_imode, "utf8-$conv")->utf8;
      my $u8hex_from_utf8 = uc unpack("H*", $u8_from_utf8);

      # set sjis-imode.
      my $sjis            = pack("H*", $sjis_hex);
      my $u8_from_sjis    = $xs->set($sjis, "sjis-$conv")->utf8;
      my $u8hex_from_sjis = uc unpack("H*", $u8_from_sjis);

      #print "$sjis_hex => $u8hex_from_sjis\n";
      #print "$ucs2_hex => $u8hex_from_utf8 (($u8_from_utf8))\n";
      is($u8hex_from_utf8, $u8hex_from_sjis, "set utf8-$conv S+$sjis_hex/U+$ucs2_hex - ($u8hex_from_sjis)");

      #
      my $u8_imode_hex = uc unpack("H*", $xs->utf8 ne '?' ? $u8_imode : '?');
      my $meth = "utf8_$conv";
      my $out = $xs->$meth();
      my $out_hex = uc unpack("H*", $out);
      #print "$sjis_hex => $u8hex_from_sjis\n";
      #print "$ucs2_hex => $u8hex_from_utf8 (($u8_from_utf8))\n";
      is($out_hex, $u8_imode_hex, "get utf8-$conv S+$sjis_hex/U+$ucs2_hex - ($out_hex)") or die "TEST";
    }
  }
}

# http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/basic/index.html
# http://www.nttdocomo.co.jp/service/imode/make/content/pictograph/extention/index.html
__DATA__
BASIC
F89F	E63E
F8A0	E63F
F8A1	E640
F8A2	E641
F8A3	E642
F8A4	E643
F8A5	E644
F8A6	E645
F8A7	E646
F8A8	E647
F8A9	E648
F8AA	E649
F8AB	E64A
F8AC	E64B
F8AD	E64C
F8AE	E64D
F8AF	E64E
F8B0	E64F
F8B1	E650
F8B2	E651
F8B3	E652
F8B4	E653
F8B5	E654
F8B6	E655
F8B7	E656
F8B8	E657
F8B9	E658
F8BA	E659
F8BB	E65A
F8BC	E65B
F8BD	E65C
F8BE	E65D
F8BF	E65E
F8C0	E65F
F8C1	E660
F8C2	E661
F8C3	E662
F8C4	E663
F8C5	E664
F8C6	E665
F8C7	E666
F8C8	E667
F8C9	E668
F8CA	E669
F8CB	E66A
F8CC	E66B
F8CD	E66C
F8CE	E66D
F8CF	E66E
F8D0	E66F
F8D1	E670
F8D2	E671
F8D3	E672
F8D4	E673
F8D5	E674
F8D6	E675
F8D7	E676
F8D8	E677
F8D9	E678
F8DA	E679
F8DB	E67A
F8DC	E67B
F8DD	E67C
F8DE	E67D
F8DF	E67E
F8E0	E67F
F8E1	E680
F8E2	E681
F8E3	E682
F8E4	E683
F8E5	E684
F8E6	E685
F8E7	E686
F8E8	E687
F8E9	E688
F8EA	E689
F8EB	E68A
F8EC	E68B
F8ED	E68C
F8EE	E68D
F8EF	E68E
F8F0	E68F
F8F1	E690
F8F2	E691
F8F3	E692
F8F4	E693
F8F5	E694
F8F6	E695
F8F7	E696
F8F8	E697
F8F9	E698
F8FA	E699
F8FB	E69A
F8FC	E69B
F940	E69C
F941	E69D
F942	E69E
F943	E69F
F944	E6A0
F945	E6A1
F946	E6A2
F947	E6A3
F948	E6A4
F949	E6A5
F972	E6CE
F973	E6CF
F974	E6D0
F975	E6D1
F976	E6D2
F977	E6D3
F978	E6D4
F979	E6D5
F97A	E6D6
F97B	E6D7
F97C	E6D8
F97D	E6D9
F97E	E6DA
F980	E6DB
F981	E6DC
F982	E6DD
F983	E6DE
F984	E6DF
F985	E6E0
F986	E6E1
F987	E6E2
F988	E6E3
F989	E6E4
F98A	E6E5
F98B	E6E6
F98C	E6E7
F98D	E6E8
F98E	E6E9
F98F	E6EA
F990	E6EB
F9B0	E70B
F991	E6EC
F992	E6ED
F993	E6EE
F994	E6EF
F995	E6F0
F996	E6F1
F997	E6F2
F998	E6F3
F999	E6F4
F99A	E6F5
F99B	E6F6
F99C	E6F7
F99D	E6F8
F99E	E6F9
F99F	E6FA
F9A0	E6FB
F9A1	E6FC
F9A2	E6FD
F9A3	E6FE
F9A4	E6FF
F9A5	E700
F9A6	E701
F9A7	E702
F9A8	E703
F9A9	E704
F9AA	E705
F9AB	E706
F9AC	E707
F9AD	E708
F9AE	E709
F9AF	E70A
F950	E6AC
F951	E6AD
F952	E6AE
F955	E6B1
F956	E6B2
F957	E6B3
F95B	E6B7
F95C	E6B8
F95D	E6B9
F95E	E6BA
EXTERNSION
F9B1	E70C
F9B2	E70D
F9B3	E70E
F9B4	E70F
F9B5	E710
F9B6	E711
F9B7	E712
F9B8	E713
F9B9	E714
F9BA	E715
F9BB	E716
F9BC	E717
F9BD	E718
F9BE	E719
F9BF	E71A
F9C0	E71B
F9C1	E71C
F9C2	E71D
F9C3	E71E
F9C4	E71F
F9C5	E720
F9C6	E721
F9C7	E722
F9C8	E723
F9C9	E724
F9CA	E725
F9CB	E726
F9CC	E727
F9CD	E728
F9CE	E729
F9CF	E72A
F9D0	E72B
F9D1	E72C
F9D2	E72D
F9D3	E72E
F9D4	E72F
F9D5	E730
F9D6	E731
F9D7	E732
F9D8	E733
F9D9	E734
F9DA	E735
F9DB	E736
F9DC	E737
F9DD	E738
F9DE	E739
F9DF	E73A
F9E0	E73B
F9E1	E73C
F9E2	E73D
F9E3	E73E
F9E4	E73F
F9E5	E740
F9E6	E741
F9E7	E742
F9E8	E743
F9E9	E744
F9EA	E745
F9EB	E746
F9EC	E747
F9ED	E748
F9EE	E749
F9EF	E74A
F9F0	E74B
F9F1	E74C
F9F2	E74D
F9F3	E74E
F9F4	E74F
F9F5	E750
F9F6	E751
F9F7	E752
F9F8	E753
F9F9	E754
F9FA	E755
F9FB	E756
F9FC	E757
