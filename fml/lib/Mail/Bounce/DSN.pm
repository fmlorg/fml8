#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: DSN.pm,v 1.2 2001/04/09 14:06:15 fukachan Exp $
#


package Mail::Bounce::DSN;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::DSN - DSN error message format parser

=head1 SYNOPSIS

=head1 DESCRIPTION


 $result = {
      addr => {
             Original-Recipient => 'rfc822; addr'
             Final-Recipient    => 'rfc822; addr'
             Diagnostic-Code    => 'reason ...'
             Action             => 'failed'
             Status             => '4.0.0'
          }
      }

=head1 METHODS

=head2 C<new()>

=cut

sub analyze
{
    my ($self, $msg) = @_;
    my $result = {};
    my $m;

    if ($m = $msg->find( { data_type => 'message/delivery-status' } )) {
	# data in the part
	my $data = $m->data;
	my $n    = $m->num_paragraph;

	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph
	    if ($buf =~ /Recipient/) {
		$self->_parse_dsn_format($buf, $result);
	    }
	}
    }
    else {
	return undef;
    }

    $result;
}


# DSN Example:
#    Final-Recipient: rfc822; rudo@nuinui.net
#    Action: failed
#    Status: 4.0.0
#    Diagnostic-Code: X-Postfix; connect to mx.nuinui.net[10.1.1.1]:
#                     Connection refused
sub _parse_dsn_format
{
    my ($self, $buf, $result) = @_;

    use Mail::Header;
    my @h      = split(/\n/, $buf);
    my $header = new Mail::Header \@h;
    my $addr   = $header->get('Original-Recipient') || 
	$header->get('Final-Recipient');


    if ($addr =~ /.*;\s*(\S+\@\S+)/) { $addr = $1;}

    # set up return buffer
    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
    for ('Final-Recipient', 'Original-Recipient',
	 'Action', 'Status', 'Diagnostic-Code') {
	$result->{ $addr }->{ $_ } = $header->get($_) || undef;
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
