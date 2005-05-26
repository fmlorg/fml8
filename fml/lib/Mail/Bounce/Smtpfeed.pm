#-*- perl -*-
#
#  Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Smtpfeed.pm,v 1.10 2004/06/30 03:05:17 fukachan Exp $
#


package Mail::Bounce::Smtpfeed;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

@ISA = qw(Mail::Bounce);

=head1 NAME

Mail::Bounce::Smtpfeed - Smtpfeed error message format parser.

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


# Descriptions: trap error pattern in To: (smtpfeed -F mode).
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m      = $msg->find( { data_type => 'message/rfc822' } );
    my $header = $m->nth_paragraph( 1 );
    my $addr   = '';

    if ($header =~
	/^To: \(original recipient in envelope at \S+\) <(\S+)>/) {
	$addr = $1;
	$addr =~ s/\s*$//o;

	# set up return buffer
	if ($addr) {
	    $addr = $self->address_clean_up($addr, $addr);
	    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
	    $result->{ $addr }->{ 'Status' }          = '5.x.y';
	    $result->{ $addr }->{ 'hints' }           = 'smtpfeed';
	}
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2004,2005 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Smtpfeed first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
