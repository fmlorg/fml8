#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: Postfix19991231.pm,v 1.2 2001/04/10 11:52:26 fukachan Exp $
#


package Mail::Bounce::Postfix19991231;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::Postfix19991231 - Postfix-19991231 error message format parser

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
    my ($self, $msg, $result) = @_;
    my $state   = 0;
    my $pattern = '--- Delivery error report follows ---';
    my $end_pattern = '--- Undelivered message follows ---';

    # search data
    my ($addr, $reason);
    my $m = $msg->{ next };
    do {
	if (defined $m) {
	    my $num  = $m->num_paragraph;
	    for ( my $i = 0; $i < $num ; $i++ ) {
		my $data = $m->nth_paragraph( $i + 1 );

		if ($data =~ /$pattern/)     { $state = 1;}
		if ($data =~ /$end_pattern/) { $state = 0;}

		if ($state == 1) {
		    $data =~ s/\n/ /g;
		    if ($data =~ /\<(\S+\@\S+\w+)\>:\s*(.*)/) {
			($addr, $reason) = ($1, $2);
			$result->{ $addr }->{ 'Diagnostic-Code' } = $reason;
			$result->{ $addr }->{ 'Status' }          = '5.x.y';
		    }
		} 
	    }
	}

	$m = $m->{ next };
    } while (defined $m);

    $result;
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
