#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: GOO.pm,v 1.2 2001/04/11 15:51:55 fukachan Exp $
#


package Mail::Bounce::GOO;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::GOO - GOO error message format parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 GOO Error Formats


=head1 METHODS

=head2 C<new()>

=cut

sub analyze
{
    my ($self, $msg, $result) = @_;
    my $hdr  = $msg->rfc822_message_header();
    my $subj = $hdr->get('subject');

    if ($subj =~ /Rejecting your mail to (\S+)/) {
	my $addr = $1;

	# set up return buffer if $addr is found.
	if ($addr) {
	    $addr =~ s/\s*$//;
	    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
	    $result->{ $addr }->{ 'Status' }          = '5.x.y';
	}
    }
}

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself. 

=head1 HISTORY

Mail::Bounce::DSN appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
