#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Smtpfeed.pm,v 1.2 2001/07/30 14:42:34 fukachan Exp $
#


package Mail::Bounce::Smtpfeed;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::Smtpfeed - Smtpfeed error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 Smtpfeed Error Formats

"smtpfeed -1 -F" sends the mail with the header rewriting of To:
header field. It will include

  To: (original recipient in envelope at ADDRESS) <ADDRESS>

at the header somewhere in the error message.

=cut


#	# smtpfeed -1 -F hack
#	if (/^To: \(original recipient in envelope at \S+\) <(\S+)>/) {
#	    &PickUpHint($1);
#	}


sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m      = $msg->find( { data_type => 'message/rfc822' } );
    my $header = $m->nth_paragraph( 1 );
    my $addr;

    #
    # XXX code below is correct ?
    #

    if ($header =~
	/^To: \(original recipient in envelope at \S+\) <(\S+)>/) {
	$addr = $1;
    }
    $addr =~ s/\s*$//;

    # set up return buffer
    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
    $result->{ $addr }->{ 'Status' }          = '5.x.y';
    $result->{ $addr }->{ 'hints' }           = 'smtpfeed';
}

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Smtpfeed appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
