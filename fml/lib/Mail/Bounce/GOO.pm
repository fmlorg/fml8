#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: GOO.pm,v 1.1 2001/04/11 16:36:19 fukachan Exp $
#


package Mail::Bounce::GOO;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::GOO - GOO error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 GOO Error Formats

   To: nospam-ml-admin@ffs.fml.org
   Subject: [goo mail] Rejecting your mail to user@mail.goo.ne.jp
   X-SMType: Notification
   Message-Id: <E12pMyv-0003Q7-00@mail.goo.ne.jp>
   Date: Wed, 10 May 2000 12:16:17 +0900
   X-UIDL: 326069d2d4e53c677fa3443428c80788
   
     ... Japanese message ...

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
	    $result->{ $addr }->{ 'hints' }           = 'goo.ne.jp';
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
