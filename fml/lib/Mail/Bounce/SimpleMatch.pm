#-*- perl -*-
#
#  Copyright (C) 2001 Ken'ichi Fukamachi
#   All rights reserved. This program is free software; you can
#   redistribute it and/or modify it under the same terms as Perl itself. 
#
# $FML: SimpleMatch.pm,v 1.22 2001/07/31 14:07:00 fukachan Exp $
#


package Mail::Bounce::SimpleMatch;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $AUTOLOAD);
use Carp;

use Mail::Bounce::Language::Japanese;
@ISA = qw(
	Mail::Bounce
	Mail::Bounce::Language::Japanese
	  );

=head1 NAME

Mail::Bounce::SimpleMatch - SimpleState error message format parser

=head1 SYNOPSIS

See C<Mail::Bounce> for more details.

=head1 DESCRIPTION

sub class used in C<Mail::Bounce>.

=head1 SIMPLE STATE MACHINE

Please write C<regexp> pattern to clarify the following states.

    state  descriptions
    ----------------------------------
      0    separator is not found yet.
      1    in error message area now

When we trap C<start>, the state changes from 0 to 1.
When we trap C<end>,   the state changes from l to 0.

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
	'start' => 'FreeML',
	'end'   => 'http\:\/\/www\.freeml\.com\/help\/',
    },


    'odn.ne.jp' => {
	'start' => 'This Message was undeliverable due to the following reason:',
    },


    'yahoo.com' => {
	'start' => 'Unable to deliver message to the following address',
	'end'   => '--- Original message follows',
    },


    'smail' => {
	'start' => 'Failed addresses follow:',
	'end'   => 'Message text follows:',
    },


    'interscan' => {
	'start' => 'Message from InterScan E-Mail VirusWall NT',
	'end'   => '     End of message     \*\*\*\*\*\*\*\*\*\*\*\*\*\*\*',
    },


    'netscape messaging server' => {
	'start' => 'This Message was undeliverable due to the following reason:',
	'end' => 'Please reply to ',
    },


    'smtp32' => {
    	'start' => 'undeliverable to',
    	'end'   => 'original message follows',
    },

    'smtpsvc' => {
    	'start' => '------Transcript of session follows -------',
    	'end'   => 'Received.*',
    },


    'sims.1' => {
	'start' => 'Your message cannot be delivered to the following recipients:',
    },

    'sims.2' => {
	'start' => '----- The following addresses had permanent fatal errors -----',
	'end'   => '----- Transcript of session follows -----',
    },


    # XXX what is this ???
    'unknown1' => {
	'start' => 'here is your list of failed recipients',
	'end'   => 'here is your returned mail',
    },

    'unknown2' => {
	'start' => 'the following addresses had',
	'end'   => 'transcript of session follows',
    },

    'unknown3' => {
	'start' => 'this message was created automatically by mail delivery software',
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
    my $m;

    # variables to hold current states
    my $args = {
	state  => 0,
	result => $result, 
    };

    # skip the first header part and search "text/*" in the body part(s). 
    $m = $msg->rfc822_message_body_head;
    $m = $m->find( { data_type_regexp => 'text' } );

    if (defined $m) {
	my $n = $m->num_paragraph;
	if ($debug) { print STDERR "   num_paragraph: $n\n";}

	for (my $i = 0; $i < $n; $i++) {
	    my $buf = $m->nth_paragraph($i + 1); # 1 not 0 for 1st paragraph
	    $args->{ buf } = \$buf;

	    if ( $self->look_like_japanese( $buf ) ) {
		if ($debug) { print STDERR "{$buf}\n";}
		$self->_japanese_address_match($args);
	    }
	    else {
		if ($debug) { print STDERR "{$buf}\n";}
		$self->_address_match($args);
	    }

	    # we found the mark of "end of error message part". 
	    last if $self->_reach_end($args);
	}
    }
    else {
	print STDERR "body object not found\n" if $debug;
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
	if ($end_regexp && ($$rbuf =~ /$end_regexp/)) {
	    print STDERR "last match {$$rbuf} ~ /$end_regexp/\n" if $debug;
	    return 1;
	}
    }

    0;
}

# XXX
# XXX our state check is applied to each paragraph not the whole body. 
# XXX
sub _address_match
{
    my ($self, $args) = @_;
    my $result = $args->{ result };
    my $rbuf   = $args->{ buf };

    unless ($args->{ state }) {
	for my $mta_type (keys %$address_trap_regexp) {
	    next unless $mta_type;

	    my $start_regexp = $address_trap_regexp->{ $mta_type }->{'start'};
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
	    print STDERR "scan($args->{ mta_type })|state=$args->{state}> $_\n"
		if $debug;
	    last SCAN if $end_regexp && /$end_regexp/;

	    if (/(\S+\@\S+)/) {
		if ($debug) { print STDERR "trap address ($1)\n";}
		my $addr = $self->address_clean_up($mta_type, $1);
		if ($addr) {
		    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
		    $result->{ $addr }->{ 'Status'}           = '5.x.y';
		    $result->{ $addr }->{ 'hints' }           = $mta_type;
		}
	    }

	    if (/$addr_regexp/) { 
		my $addr = $self->address_clean_up($mta_type, $1);
		if ($addr) {
		    $result->{ $addr }->{ 'Final-Recipient' } = $addr;
		    $result->{ $addr }->{ 'Status'}           = '5.x.y';
		    $result->{ $addr }->{ 'hints' }           = $mta_type;
		}
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
