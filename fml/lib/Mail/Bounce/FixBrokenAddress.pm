#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: FixBrokenAddress.pm,v 1.3 2001/09/18 03:31:33 fukachan Exp $
#


package Mail::Bounce::FixBrokenAddress;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = $ENV{'debug'} ? 1 : 0;

@ISA = qw(Mail::Bounce);


=head1 NAME

Mail::Bounce::FixBrokenAddress - handles irregular error message

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE


=cut


sub FixIt
{
    my ($hint, $addr) = @_;

    if ($debug) {
	print STDERR "FixIt($hint, $addr)\n";
    }

    # error address from nifty.ne.jp has no domain part ;)
    if ($hint eq 'nifty.ne.jp' && $addr !~ /\@/) {
	return( $addr . '@nifty.ne.jp' );
    }
    # looks like URL for DB
    # e.g. errorperson?user-id=102624708&subscriber-id=94219786@webtv.ne.jp
    elsif ($hint =~ /webtv.ne.jp/ && $addr =~ /\?/) {
	if ($addr =~ /^(\S+)\?/) {
	    return( $1 .'@webtv.ne.jp' );
	}
    }
    # return $addr itself by default (not match anything)
    else {
	return $addr;
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::FixBrokenAddress appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
