#-*- perl -*-
#
#  Copyright (C) 2001,2002 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself.
#
# $FML: Postfix19991231.pm,v 1.12 2002/01/13 06:23:27 fukachan Exp $
#


package Mail::Bounce::Postfix19991231;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

@ISA = qw(Mail::Bounce);

=head1 NAME

Mail::Bounce::Postfix19991231 - Postfix-19991231 error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

subclass used in C<Mail::Bounce>.

=head1 ERROR FORMAT

   Date: Fri, 29 Jan 1999 15:05:06 +0900 (JST)
   From: MAILER-DAEMON@fml.org (Mail Delivery System)
   Subject: Undelivered Mail Returned to Sender
   To: fukachan@fml.org
   Message-Id: <19990129060506.816AD5B33D@katri.fml.org>

   This is the Postfix program at host katri.fml.org.

       ... reason ...

   	--- Delivery error report follows ---

   <rudo@nuinui.net>: mail to command is restricted

   	--- Undelivered message follows ---

   ... original message ...

=cut


# Descriptions: trap error of old postfix style
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub analyze
{
    my ($self, $msg, $result) = @_;
    my $data_type = $msg->rfc822_message_header_data_type();

    if ($data_type =~ /multipart/i) {
	$self->_analyze_broken_dsn($msg, $result);
    }
    else {
	$self->_analyze_plaintext($msg, $result);
    }
}


# Descriptions: analyze postfix error message
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub _analyze_plaintext
{
    my ($self, $msg, $result) = @_;
    my $state       = 0;
    my $pattern     = '--- Delivery error report follows ---';
    my $end_pattern = '--- Undelivered message follows ---';

    # search data
    my ($addr, $reason);
    my $m = $msg->{ next };
    do {
	if (defined $m) {
	    my $num  = $m->num_paragraph;
	    for ( my $i = 0; $i < $num ; $i++ ) {
		my $data = $m->nth_paragraph( $i + 1 );

		# debug
		print STDERR "paragraph($i){$data}\n" if $ENV{'debug'};

		if ($data =~ /$pattern/)     { $state = 1;}
		if ($data =~ /$end_pattern/) { $state = 0;}

		if ($state == 1) {
		    $data =~ s/\n/ /g;
		    if ($data =~ /\<(\S+\@\S+\w+)\>:\s*(.*)/) {
			$self->_parse_address($data, $result);
		    }
		}
	    }
	}

	$m = $m->{ next };
    } while (defined $m);

    $result;
}


# Descriptions: analyze postfix error message II
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub _analyze_broken_dsn
{
    my ($self, $msg, $result) = @_;
    my $m = $msg->find( { data_type => 'text/plain' } );

    if (defined $m) {
	my $num  = $m->num_paragraph;
	for ( my $i = 0; $i < $num ; $i++ ) {
	    my $data = $m->nth_paragraph( $i + 1 );

	    # debug
	    print STDERR "paragraph($i){$data}\n" if $ENV{'debug'};

	    if ($data =~ /\<(\S+\@\S+\w+)\>:\s*(.*)/) {
		$self->_parse_address($data, $result);
	    }
	}
    }
    else {
	undef;
    }
}


# Descriptions: clean up address
#    Arguments: OBJ($self) OBJ($msg) HASH_REF($result)
# Side Effects: update $result
# Return Value: none
sub _parse_address
{
    my ($self, $data, $result) = @_;

    if ($data =~ /\<(\S+\@\S+\w+)\>:\s*(.*)/) {
	my ($addr, $reason) = ($1, $2);
	$addr = $self->address_clean_up($self, $addr);
	$result->{ $addr }->{ 'Diagnostic-Code' } = $reason;
	$result->{ $addr }->{ 'Status' }          = '5.x.y';
	$result->{ $addr }->{ 'hints' }           = 'postfix 19991231 style';
    }
}


=head1 AUTHOR

Ken'ichi Fukamachi

=head1 COPYRIGHT

Copyright (C) 2001 Ken'ichi Fukamachi

All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 HISTORY

Mail::Bounce::Postfix19991231 appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
