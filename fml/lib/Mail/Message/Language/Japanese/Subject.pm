#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Subject.pm,v 1.16 2003/08/23 04:35:48 fukachan Exp $
#


###                                                   ###
### CAUTION: THE CHARSET OF THIS FILE IS "EUC-JAPAN". ###
###                                                   ###


package Mail::Message::Language::Japanese::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Jcode;

=head1 NAME

Mail::Message::Language::Japanese::Subject - functions for Japanese subject.

=head1 SYNOPSIS

 use Mail::Message::Language::Japanese::Subject;
 $is_reply = Mail::Message::Language::Japanese::Subject::is_reply($subject);

=head1 DESCRIPTION

a collection to handle Japanese specific representations which appears
in the subject.

=cut


# XXX-TODO: we should it in proper way in the future.
# XXX-TODO: but we import it anyway for further rewriting.
my $CUT_OFF_RERERE_PATTERN = '';
my $CUT_OFF_RERERE_HOOK    = '';


# subjec reply pattern
# apply patch from OGAWA Kunihiko <kuni@edit.ne.jp>
#            fml-support:7626 7653 07666
#            Re: Re2:   Re[2]:     Re(2):     Re^2:    Re*2:
# i-mode ? (PR fml-help: 00157 by OGAWA Kunihiko)
my $pattern  = 'Re:|Re\d+:|Re\[\d+\]:|Re\(\d+\):|Re\^\d+:|Re\*\d+:|Re>';
   $pattern .= '|(返信|返|ＲＥ|Ｒｅ)(\s*:|：)';


=head1 METHODS

=cut


# Descriptions: constructor.
#    Arguments: OBJ($self) HASH_REF($args)
# Side Effects: none
# Return Value: OBJ
sub new
{
    my ($self, $args) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


=head2 is_reply($string)

check whether C<$string> looks like a reply message.
C<$string> is a C<Subject:> of the mail header.
For example, it is like this:

  Re: reply to your messages

=cut


# Descriptions: looks reply message ?
#    Arguments: OBJ($self) STR($x)
# Side Effects: none
# Return Value: 1 or 0
sub is_reply
{
    my ($self, $x) = @_;

    return 0 unless $x;

    &Jcode::convert(\$x, 'euc');
    return ($x =~ /^((\s|(　))*($pattern)\s*)+/ ? 1 : 0);
}


=head2 cut_off_reply_tag($subject)

cut off C<Re:> in the string C<$subject> like C<Re: ... >
within C<Subject:>.

=cut


# fml-support: 07507
# sub CutOffRe
# {
#    いままでどおりの Re: とかとっぱらう
#
#   if ($LANGUAGE eq 'Japanese') {
#	日本語処理依存ライブラリへ飛ぶ
#	この中で $CUT_OFF_PATTERN (config.ph)などにしたがって
#	切り落とすのも良し（きっと日本語を書くだろうとおもうわけで
#	で、このライブラリの先で実行する）
#   }
#
#   run-hooks $CUT_OFF_HOOK(ユーザ定義HOOK)
#}
# レレレ対策


# Descriptions: remove Re: strings.
#    Arguments: OBJ($self) STR($subject)
# Side Effects: none
# Return Value: STR
sub cut_off_reply_tag
{
    my ($self, $subject) = @_;
    my ($y, $limit);

    Jcode::convert(\$subject, 'euc');

    if ($CUT_OFF_RERERE_PATTERN) {
	Jcode::convert(\$CUT_OFF_RERERE_PATTERN, 'euc');
    }

    $pattern .= '|' . $CUT_OFF_RERERE_PATTERN if ($CUT_OFF_RERERE_PATTERN);

    # fixed by OGAWA Kunihiko <kuni@edit.ne.jp> (fml-support: 07815)
    # $subject =~ s/^((\s*|(　)*)*($pattern)\s*)+/Re: /oi;
    $subject =~ s/^((\s|(　))*($pattern)\s*)+/Re: /oi;

    if ($CUT_OFF_RERERE_HOOK) {
	eval($CUT_OFF_RERERE_HOOK);
	&Log($@) if $@;
    }

    Jcode::convert(\$subject, 'jis');
    $subject;
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

Mail::Message::Language::Japanese::Subject
first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
