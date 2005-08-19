#-*- perl -*-
#
#  Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: DSN.pm,v 1.24 2004/06/30 03:05:15 fukachan Exp $
#


package Mail::Bounce::DSN;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

my $debug = 0;

@ISA = qw(Mail::Bounce);


=head1 NAME

Mail::Bounce::DSN - DSN error message format parser.

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

See C<Mail::Bounce> for more details.

=head1 ERROR EXAMPLE

See RFC1894 on DSN (Delivery Status Notification) definition.

   From: MAILER-DAEMON@ahodori.fml.org (Mail Delivery System)
   Subject: Undelivered Mail Returned to Sender
   To: fml-help-admin@ffs.fml.org
   MIME-Version: 1.0
   Content-Type: multipart/report; report-type=delivery-status;
   	boundary="C687D866E0.986737575/ahodori.fml.org"
   Message-Id: <20010408134615.F1DD786658@ahodori.fml.org>

   This is a MIME-encapsulated message.

   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Notification
   Content-Type: text/plain

   This is the Postfix program at host ahodori.fml.org.

       ... reason ...

   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Delivery error report
   Content-Type: message/delivery-status

   Reporting-MTA: dns; ahodori.fml.org
   Arrival-Date: Sun, 25 Mar 2001 22:34:15 +0900 (JST)

   Final-Recipient: rfc822; rudo@nuinui.net
   Action: failed
   Status: 4.0.0
   Diagnostic-Code: X-Postfix; connect to sv.nuinui.net[10.0.0.1]:
       Connection refused

   --C687D866E0.986737575/ahodori.fml.org
   Content-Description: Undelivered Message
   Content-Type: message/rfc822

       ... original message ...

   -- rudo's mabuachi

   --C687D866E0.986737575/ahodori.fml.org--

=cut


# Descriptions: analyze DSN format message.
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m = $msg->whole_message_body_head;
    $m    = $m->find( { data_type => 'message/delivery-status' } );

    if (defined $m) {
	# data in the part
	my $data = $m->message_text;
	my $n    = $m->num_paragraph;

	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph
	    if ($buf =~ /Recipient/) {
		$self->_parse_dsn_format($buf, $result);
	    }
	}

	if ($debug) {
	    print STDERR "\t * no recipient information\n" unless %$result;
	}
    }
    else {
	return undef;
    }

    return $result;
}


# Descriptions: DSN parser.
#               [DSN Example]
#               Final-Recipient: rfc822; rudo@nuinui.net
#               Action: failed
#               Status: 4.0.0
#               Diagnostic-Code: X-Postfix; connect to mx.nuinui.net[10.1.1.1]:
#                    Connection refused
#    Arguments: OBJ($self) STR($buf) HASH_REF($result)
# Side Effects: update $result.
# Return Value: none
sub _parse_dsn_format
{
    my ($self, $buf, $result) = @_;

    use Mail::Header;
    my @h      = split(/\n/, $buf);
    my $header = new Mail::Header \@h;
    my $addr   = $header->get('Original-Recipient') ||
	$header->get('Final-Recipient');

    if ($addr =~ /.*;\s*(\S+\@\S+\w+)/) { $addr = $1;}
    $addr = $self->address_cleanup($self, $addr);

    # gives $addr itself as a hint of fixing broken address
    # domain part of $addr may match someting e.g. nifty.ne.jp, webtv.ne.jp.
    $addr = $self->address_cleanup($addr, $addr);

    if ($debug) {
	print STDERR "\t *** valid address is not found\n" unless $addr;
    }

    # set up return buffer
    if ($addr =~ /\@/o) {
	$result->{ $addr }->{ 'Final-Recipient' } = $addr;
	for my $var (qw(Final-Recipient
			Original-Recipient
			Action
			Status
			Diagnostic-Code
			Reporting-MTA
			Received-From-MTA)) {
	    $result->{ $addr }->{ $var } = $header->get($var) || undef;
	}
	$result->{ $addr }->{ 'hints' } = 'DSN';
    }
}


=head1 CODING STYLE

See C<http://www.fml.org/software/FNF/> on fml coding style guide.

=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001,2002,2003,2004 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::DSN first appeared in fml8 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
