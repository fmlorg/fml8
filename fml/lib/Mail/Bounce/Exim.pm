#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Exim.pm,v 1.6 2002/01/16 13:34:02 fukachan Exp $
#


package Mail::Bounce::Exim;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::Exim - Exim error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE

 Received: from fukachan by eriko.fml.org with local (Exim 2.04 #5)
        id 11fxjP-0005MW-00
        for enterprise-admin@shumi.fml.org; Tue, 26 Oct 1999 12:57:07 +0900
 X-Failed-Recipients: rudo@nuinui.net
 From: Mail Delivery System <Mailer-Daemon@eriko.fml.org>
 To: enterprise-admin@shumi.fml.org
 Subject: Mail delivery failed: returning message to sender
 Message-Id: <E11fxjP-0005MW-00@eriko.fml.org>

=head1 TODO

need to guess MTA as "exim" ???

	if (/^Message-ID:\s+\<[\w\d]+\-[\w\d]+\-[\w\d]+\@/i) {
	    $MTA = "exim";
	}

=cut


# Descriptions: trap X-Failed-Recipients: exim returns.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m    = $msg->whole_message_header();
    my $addr = $m->get('X-Failed-Recipients');

    # set up return buffer if $addr is found.
    if ($addr) {
	$addr =~ s/\s*$//;
	$result->{ $addr }->{ 'Final-Recipient' } = $addr;
	$result->{ $addr }->{ 'Status' }          = '5.x.y';
	$result->{ $addr }->{ 'hints' }           = 'exim';
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::DSN appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
