#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Smtpfeed.pm,v 1.1 2001/04/10 14:34:19 fukachan Exp $
#


package Mail::Bounce::Smtpfeed;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::Smtpfeed - Smtpfeed error message format parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 Smtpfeed Error Formats

=head1 METHODS

=head2 C<new()>

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
