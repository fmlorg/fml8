#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: SimpleMatch.pm,v 1.4 2001/04/12 03:30:30 fukachan Exp $
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


    'caiwireless.net' => {
	'start' => 'the following recipients did not receive this message:',
    },


    'compuserve.net' => {
	'start'  => 'your message could not be delivered',
	'regexp' => 'Invalid receiver address: (\S+\@\S+)',
    },


    'nifty.ne.jp' => {
	'start'  => '----- Unsent reason follows --',
	'end'    => '----- Unsent message follows --',
	'regexp' => '(\S+) could not receive a mail that you had sent',
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
    my ($match, $state);

    for my $which (keys %$address_trap_regexp) {
	next unless $which;

	my $start_regexp = $address_trap_regexp->{ $which }->{ 'start' };
	if ($$rbuf =~ /$start_regexp/) { 
	    $match = $which;
	    $state = 1;
	}
    }

    # not found
    return unless $match;

    # found
    my $end_regexp  = $address_trap_regexp->{ $match }->{ 'end' };
    my $addr_regexp = $address_trap_regexp->{ $match }->{ 'regexp' };

    # 1.1 o.k. we've found the start pattern !!
    if ($state == 1) {
	my @buf = split(/\n/, $$rbuf);

      SCAN:
	for (@buf) {
	    print "scan> $_\n" if $debug;
	    last SCAN if /$end_regexp/;

	    if (/(\S+\@\S+)/) { 
		my $addr = $self->_clean_up($match, $1);
		$result->{ $addr }->{ 'Final-Recipient' } = $addr;
		$result->{ $addr }->{ 'Status'} = '5.x.y';
	    }

	    if (/$addr_regexp/) { 
		my $addr = $self->_clean_up($match, $1);
		$result->{ $addr }->{ 'Final-Recipient' } = $addr;
		$result->{ $addr }->{ 'Status'} = '5.x.y';
	    }
	}
    }
}


sub _clean_up
{
    my ($self, $type, $addr) = @_;

    $addr =~ s/^<//;
    $addr =~ s/>$//;

    if ($type eq 'nifty.ne.jp') {
	return $addr .'@nifty.ne.jp';
    }
    else {
	$addr;
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
