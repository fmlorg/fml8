#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: SimpleMatch.pm,v 1.6 2001/04/12 11:47:16 fukachan Exp $
#


package Mail::Bounce::SimpleMatch;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

@ISA = qw(Mail::Bounce);

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


    'freeml.com' => {
	'start' => '.',
	'end'   => 'http\:\/\/www\.freeml\.com\/help\/',
    },


    'smail' => {
	'start' => 'Failed addresses follow:',
	'end'   => 'Message text follows:',
    },


    # XXX what is this ???
    'smtp32' => {
	'start' => '.',
	'end'   => 'original message follows',
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

    # process control block
    my $args = {
	state  => 0,
	result => $result, 
    };

    # skip the first header part and search "text/*" in the body part(s). 
    my $m = $msg->rfc822_message_body_head;
    $m = $m->find( { data_type_regexp => 'text' } );

    if (defined $m) {
	my $n = $m->num_paragraph;
	if ($debug) { print "   num_paragraph: $n\n";}

	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph
	    $args->{ buf } = \$buf;

	    unless ( $self->look_japanese( $buf ) ) {
		if ($debug) { print "{$buf}\n";}
		$self->_address_match($args);
	    }

	    # we found the mark of "end of error message part". 
	    last if $self->_reach_end($args);
	}
    }
    else {
	print "body object not found\n" if $debug;
    }
}


sub _reach_end
{
    my ($self, $args) = @_;
    my $result = $args->{ result };
    my $rbuf   = $args->{ buf };

    for my $mta_type (keys %$address_trap_regexp) {
	next unless $mta_type;

	my $end_regexp = $address_trap_regexp->{ $mta_type }->{ 'end' };
	return 1 if ($$rbuf =~ /$end_regexp/);
    }

    0;
}


sub _address_match
{
    my ($self, $args) = @_;
    my $result = $args->{ result };
    my $rbuf   = $args->{ buf };

    unless ($args->{ state }) {
	for my $mta_type (keys %$address_trap_regexp) {
	    next unless $mta_type;

	    my $start_regexp = $address_trap_regexp->{ $mta_type }->{ 'start' };
	    if ($$rbuf =~ /$start_regexp/) { 
		$args->{ mta_type  } = $mta_type;
		$args->{ state }     = 1;
	    }
	}

	# not found
	return unless $args->{ state };
    }

    # found
    my $mta_type    = $args->{ mta_type };
    my $end_regexp  = $address_trap_regexp->{ $mta_type }->{ 'end' };
    my $addr_regexp = $address_trap_regexp->{ $mta_type }->{ 'regexp' };
    
    # 1.1 o.k. we've found the start pattern !!
    if ($args->{ state } == 1) {
	my @buf = split(/\n/, $$rbuf);

      SCAN:
	for (@buf) {
	    print "scan> $_\n" if $debug;
	    last SCAN if /$end_regexp/;

	    if (/(\S+\@\S+)/) { 
		my $addr = $self->_addr_clean_up($mta_type, $1);
		if ($addr) {
		    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
		    $result->{ $addr }->{ 'Status'}           = '5.x.y';
		}
	    }

	    if (/$addr_regexp/) { 
		my $addr = $self->_addr_clean_up($mta_type, $1);
		if ($addr) {
		    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
		    $result->{ $addr }->{ 'Status'}           = '5.x.y';
		}
	    }
	}
    }
}


sub _addr_clean_up
{
    my ($self, $type, $addr) = @_;

    # nuke predecing and trailing strings around user@domain pattern
    my $prev_addr = $addr;
    do { 
	$prev_addr = $addr;
	$addr      =~ s/\.$//;
	$addr      =~ s/^<//;
	$addr      =~ s/>$//;
    } while ($addr ne $prev_addr);

    if ($type eq 'nifty.ne.jp' && $addr !~ /\@/) {
	$addr . '@nifty.ne.jp';
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
