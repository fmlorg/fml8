#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $Id$
# $FML$
#

package Dialect::Japanese::Subject;
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Jcode;

require Exporter;
@ISA = qw(Exporter);

# XXX we should it in proper way in the future.
# XXX but we import it anyway for further rewriting.
my $CUT_OFF_RERERE_PATTERN;
my $CUT_OFF_RERERE_HOOK;


# subjec reply pattern
# apply patch from OGAWA Kunihiko <kuni@edit.ne.jp> 
#            fml-support:7626 7653 07666
#            Re: Re2:   Re[2]:     Re(2):     Re^2:    Re*2:
my $pattern  = 'Re:|Re\d+:|Re\[\d+\]:|Re\(\d+\):|Re\^\d+:|Re\*\d+:';
   $pattern .= '|(返信|返|ＲＥ|Ｒｅ)(\s*:|：)';


sub new
{
    my ($self) = @_;
    my ($type) = ref($self) || $self;
    my $me     = {};
    return bless $me, $type;
}


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
sub cut_off_reply_tag
{
    my ($subject) = @_;
    my ($y, $limit);

    Jcode::convert(\$subject, 'euc');

    if ($CUT_OFF_RERERE_PATTERN) {
	Jcode::convert(*CUT_OFF_RERERE_PATTERN, 'euc');
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


sub is_reply
{
    my ($self, $x) = @_;
    return 0 unless $x;
    &Jcode::convert(\$x, 'euc');
    return ($x =~ /^((\s|(　))*($pattern)\s*)+/ ? 1 : 0);
}


=head1 NAME

Dialect::Japanese::Subject.pm - what is this


=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 new

=item Function()


=head1 AUTHOR

 Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Dialect::Japanese::Subject appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
