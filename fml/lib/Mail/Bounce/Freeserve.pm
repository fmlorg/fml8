#-*- perl -*-
#
#  Copyright (C) 2003,2004 MURASHITA Takuya
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Freeserve.pm,v 1.5 2004/06/30 03:05:16 fukachan Exp $
#

#
# *** CAUTION: THIS FILE CODE IS JAPANESE EUC. ***
#

package Mail::Bounce::Freeserve;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::Freeserve - Freeserve error message format parser.

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 Freeserve Error Formats

    To: nospam-ml-admin@ffs.fml.org
    Message-Id: <200308051027.h75ARXb26220@fbe.freeserve.ne.jp>
    X-Loop: erroraddress@fbe.freeserve.ne.jp
    From: support@freeserve.ne.jp
    Subject: ... Japanese message ...

	... Japanese message ...

    http://www.freeserve.ne.jp/
    support@freeserve.ne.jp

X-Loop contains the address which causes this error.

See L<Mail::Bounce::Language::Japanese> module for the Japanese
message.

=cut


# Descriptions: trap error pattern in subject from goo.ne.jp.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub analyze
{
    my ($self, $msg, $result) = @_;
    my $hdr   = $msg->whole_message_header();
    my $xloop = $hdr->get('x-loop');

    if ($xloop =~ /([^\s\@]+@\S+\.freeserve\.ne\.jp)$/) {
	my $addr = $1;

	# set up return buffer if $addr is found.
	# XXX-TODO: we should use $self->address_clean_up() ?
	if ($addr) {
	    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
	    $result->{ $addr }->{ 'Status' }          = '4.x.y';
	    $result->{ $addr }->{ 'hints' }           = 'freeserve.ne.jp';
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

MURASHITA Takuya

=head1 COPYRIGHT

Copyright (C) 2003,2004 MURASHITA Takuya

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Freeserve first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut

1;
