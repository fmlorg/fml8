#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Japanese.pm,v 1.9 2003/08/13 13:43:46 fukachan Exp $
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

   �������顼��ݡ���

    ��̾:        [XXXXXXX:08268] Re: �ܤ����

    ������:      xxxxxxxx@chuo.tokyo.nuinui.net

    ����:        The peer SMTP host reports that it received bad SMTP command
                 syntax.

=head2 jp-r.ne.jp

   ������E-mail���ɥ쥹���԰��פǤ�
   To:****@jp-r.ne.jp
   Subject:** ���ä�subject������
   ** ���ä���ʸ��192ʸ����������

=head2 pakeo.ne.jp

  ���ʤ��������Ȥ������ɥ쥹��*********�פϡ���Ͽ����Ƥ��ޤ���
  �⤦���ٳ�ǧ���ơ��������ʤ����Ʋ�������

=head2 freeserve.ne.jp

    To: nospam-ml-admin@ffs.fml.org
    Message-Id: <200308051027.h75ARXb26220@fbe.freeserve.ne.jp>
    X-Loop: erroraddress@fbe.freeserve.ne.jp
    From: support@freeserve.ne.jp
    Subject: ��freeserve�����᡼��ۥ᡼��������뤳�Ȥ�����ޤ���Ǥ�����

   �ڤ��Υ᡼���freeserve�����ƥफ�鼫ưŪ����������Ƥ��ޤ���

    freeserve�Ǥϥ᡼��ܥå������������¤�����ޤ���
    ���ʤ��ͤ��᡼������ä�freeserve�桼�����Υ᡼��ܥå����������ͤ�ã���Ƥ�
    �ꡢ������ˤʤä��᡼��������뤳�Ȥ�����ޤ���Ǥ�����

    http://www.freeserve.ne.jp/
    support@freeserve.ne.jp

=cut


# Descriptions: trap Japanese specific error address.
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

    # XXX-TODO: use Mail::Message::Encode.
    use Jcode;
    &Jcode::convert(\$buf, 'euc');

    print STDERR "rbuf={$buf}\n" if $debug;

    # lotus NOTES
    if ($buf =~ /������:\s*(\S+)/) {
	$addr     = $1;
	$mta_type = 'lotus notes';
    }
    # ������E-mail���ɥ쥹���԰��פǤ�
    # To:****@jp-r.ne.jp
    elsif ($buf =~ /To:\s*(\S+jp-r.ne.jp)/i) {
	$addr     = $1;
	$mta_type = 'jp-r.ne.jp';
    }
    # ���ʤ��������Ȥ������ɥ쥹��**@i.pakeo.ne.jp�פϡ���Ͽ����Ƥ��ޤ���
    elsif ($buf =~
	   /���ʤ��������Ȥ������ɥ쥹��(.*)�פϡ���Ͽ����Ƥ��ޤ���/) {
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

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Language::Japanese first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
