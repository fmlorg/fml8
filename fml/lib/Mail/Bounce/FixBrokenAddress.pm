#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: FixBrokenAddress.pm,v 1.11 2004/01/24 09:00:54 fukachan Exp $
#


package Mail::Bounce::FixBrokenAddress;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

@ISA = qw(Mail::Bounce);


=head1 NAME

Mail::Bounce::FixBrokenAddress - handle irregular error message.

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE

=cut


# Descriptions: speculate correct address.
#    Arguments: STR($hint) STR($addr)
# Side Effects: speculate $addr
# Return Value: STR($addr)
sub FixIt
{
    my ($hint, $addr) = @_;

    if ($debug) {
	print STDERR "FixIt($hint, $addr)\n";
    }

    # error address from nifty.ne.jp has no domain part ;)
    if ($hint eq 'nifty.ne.jp' && $addr !~ /\@/o) {
	return( $addr . '@nifty.ne.jp' );
    }
    # looks like URL for DB
    # e.g. errorperson?user-id=102624708&subscriber-id=94219786@webtv.ne.jp
    elsif ($hint =~ /webtv.ne.jp/ && $addr =~ /\?/o) {
	if ($addr =~ /^(\S+)\?/) {
	    return( $1 .'@webtv.ne.jp' );
	}
    }
    # return $addr itself by default (not match anything)
    else {
	return $addr;
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::FixBrokenAddress first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
