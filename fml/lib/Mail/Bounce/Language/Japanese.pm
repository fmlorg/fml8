#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Japanese.pm,v 1.6 2002/09/11 23:18:23 fukachan Exp $
#

#
# *** CAUTION: THIS FILE CODE IS JAPANESE EUC. ***
#

package Mail::Bounce::Language::Japanese;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

@ISA = qw(Mail::Bounce);


=head1 NAME

Mail::Bounce::Language::Japanese - Japanese dependent error message parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE

=head2 Lotus Notes

   送信エラーレポート

    件名:        [XXXXXXX:08268] Re: ぼくルド

    送信先:      xxxxxxxx@chuo.tokyo.nuinui.net

    原因:        The peer SMTP host reports that it received bad SMTP command
                 syntax.

=head2 jp-r.ne.jp

   送信先E-mailアドレスの不一致です
   To:****@jp-r.ne.jp
   Subject:** 送ったsubjectが入る
   ** 送った本文が192文字程度入る

=head2 pakeo.ne.jp

  あなたが送ろうとしたアドレス「*********」は、登録されていません。
  もう一度確認して、送信しなおして下さい。

=cut


# Descriptions: trap Japanese specific error address
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: update $args->{result}
# Return Value: none
sub _japanese_address_match
{
    my ($self, $args) = @_;
    my ($addr, $mta_type);
    my $result = $args->{ result };
    my $rbuf   = $args->{ buf };
    my $buf    = $$rbuf;

    use Jcode;
    &Jcode::convert(\$buf, 'euc');

    print STDERR "rbuf={$buf}\n" if $debug;

    # lotus NOTES
    if ($buf =~ /送信先:\s*(\S+)/) {
	$addr     = $1;
	$mta_type = 'lotus notes';
    }
    # 送信先E-mailアドレスの不一致です
    # To:****@jp-r.ne.jp
    elsif ($buf =~ /To:\s*(\S+jp-r.ne.jp)/i) {
	$addr     = $1;
	$mta_type = 'jp-r.ne.jp';
    }
    # あなたが送ろうとしたアドレス「**@i.pakeo.ne.jp」は、登録されていません
    elsif ($buf =~
	   /あなたが送ろうとしたアドレス「(.*)」は、登録されていません/) {
	$addr     = $1;
	$mta_type = 'pakeo.ne.jp';
    }

    if ($addr) {
	$result->{ $addr }->{ 'Final-Recipient' } = $addr;
	$result->{ $addr }->{ 'Status'}           = '5.x.y';
	$result->{ $addr }->{ 'hints' }           = $mta_type;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Language::Japanese first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
