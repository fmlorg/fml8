#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: SimpleMatch.pm,v 1.2 2001/04/11 16:37:49 fukachan Exp $
#


package Mail::Bounce::SimpleMatch;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

=head1 NAME

Mail::Bounce::SimpleMatch - SimpleState error message format parser

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SIMPLE STATE MACHINE

Please write C<regexp> pattern to clarify the following states.

    state  descriptions
    ----------------------------------
      0    separator is not found yet.
      1    in error message area now

When we trap C<start>, the state changes from 0 to 1.
When we trap C<end>,   the state changes from l to 0.

=head1 METHODS

=head2 C<new()>

=cut


my $debug = $ENV{'debug'} ? 1 : 0;

my $address_trap_regexp = {
    'biglobe.ne.jp' => {
	'start' => '----- The following addresses had delivery problems -----',
	'end'   => '----- Non-delivered information -----',
    },

    'smail' => {
	'start' => 'Failed addresses follow:',
	'end'   => 'Message text follows:',
    },
};

my $reason_trap_regexp = {
    'biglobe.ne.jp' => {
	'start' => '----- Non-delivered information -----',
	'end'   => '',
    },
};


sub analyze
{
    my ($self, $msg, $result) = @_;
    my $m;

    # skip the first header part and search "text/*" in the body part(s). 
    $m = $msg->rfc822_message_body_head;
    $m = $m->find( { data_type_regexp => 'text' } );

    if (defined $m) {
	my $n = $m->num_paragraph;
	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph

	    # 1. search start pattern
	    $self->_address_match($result, \$buf);
	}
    }
}


sub _address_match
{
    my ($self, $result, $rbuf) = @_;
    my ($start_regexp, $end_regexp, $which, $state);

    for $which (keys %$address_trap_regexp) {
	$start_regexp = $address_trap_regexp->{ $which }->{ 'start' };
	$end_regexp   = $address_trap_regexp->{ $which }->{ 'end' };
	if ($$rbuf =~ /$start_regexp/) { $state = 1;}
    }

    # 1.1 o.k. we've found the start pattern !!
    if ($state == 1) {
	my @buf = split(/\n/, $$rbuf);

      SCAN:
	for (@buf) {
	    print "scan> $_\n" if $debug;
	    last SCAN if /$end_regexp/;

	    if (/(\S+\@\S+)/) { 
		my $addr = $1;
		$addr =~ s/^<//;
		$addr =~ s/>$//;
		$result->{ $addr }->{ 'Final-Recipient' } = $addr;
		$result->{ $addr }->{ 'Status'} = '5.x.y';
	    }
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

Mail::Bounce::SimpleMatch appeared in fml5 mailing list driver package.
See C<http://www.fml.org/> for more details.

=cut


1;
